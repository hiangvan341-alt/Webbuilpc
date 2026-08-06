import * as XLSX from 'xlsx'
import type { CategoryKey, ImportedProduct } from '../types'

const normalize = (value: unknown) => String(value ?? '').trim().replace(/\s+/g, ' ')
const headerKey = (value: unknown) => normalize(value).toLowerCase()
const plain = (value: string) => value.normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/đ/g, 'd').toLowerCase()

const CATEGORY_RULES: Array<{ category: CategoryKey; patterns: RegExp[] }> = [
  { category: 'cpu', patterns: [/^cpu$/, /bo vi xu ly/, /processor/] },
  { category: 'mainboard', patterns: [/^mainboard$/, /bo mach chu/, /motherboard/] },
  { category: 'ram', patterns: [/^ram$/, /bo nho trong/] },
  { category: 'gpu', patterns: [/^vga$/, /card man hinh/, /card do hoa/, /graphics card/] },
  { category: 'ssd', patterns: [/ssd/, /hdd/, /o cung/, /storage/] },
  { category: 'psu', patterns: [/^psu/, /nguon may tinh/, /power supply/] },
  { category: 'case', patterns: [/^case$/, /vo may tinh/, /vo case/] },
  { category: 'cooler', patterns: [/tan nhiet/, /cooler/] },
  { category: 'monitor', patterns: [/man hinh/, /monitor/] },
  { category: 'accessory', patterns: [/phu kien/, /phim chuot/, /ban ghe/, /gear/] },
]

const NON_COMPONENT_GROUPS = [/phu phi/, /^dich vu$/, /^combo$/, /aio - all in one/, /^aio$/]

export function mapCategory(groupName: string): CategoryKey | null {
  const g = plain(groupName)
  if (NON_COMPONENT_GROUPS.some(pattern => pattern.test(g))) return null
  return CATEGORY_RULES.find(rule => rule.patterns.some(pattern => pattern.test(g)))?.category ?? 'accessory'
}

function inferBrand(name: string): string {
  const cleaned = normalize(name)
    .replace(/^(CPU|Mainboard|RAM|VGA|SSD|HDD|PSU|Case|Tản nhiệt|Màn hình|Card màn hình|Ổ cứng|Nguồn máy tính)\s+/i, '')
  return cleaned.split(/[\s(-]/).filter(Boolean)[0] || 'Khác'
}

function parseNumber(value: unknown): number {
  if (typeof value === 'number') return Number.isFinite(value) ? value : 0
  const text = normalize(value).replace(/[^\d.,-]/g, '')
  if (!text) return 0
  const separators = (text.match(/[.,]/g) || []).length
  const normalized = separators > 1 || /[.,]\d{3}$/.test(text) ? text.replace(/[.,]/g, '') : text.replace(',', '.')
  const number = Number(normalized)
  return Number.isFinite(number) ? number : 0
}

export async function parseProductWorkbook(file: File): Promise<ImportedProduct[]> {
  const workbook = XLSX.read(await file.arrayBuffer(), { type: 'array' })
  const sheet = workbook.Sheets[workbook.SheetNames[0]]
  const rows: Record<string, unknown>[] = XLSX.utils.sheet_to_json<Record<string, unknown>>(sheet, { defval: '' })

  return rows.map((row) => {
    const lookup = new Map(Object.entries(row).map(([k, v]) => [headerKey(k), v]))
    const group = normalize(lookup.get('nhóm hàng(3 cấp)'))
    const name = normalize(lookup.get('tên hàng'))
    const category = mapCategory(group)
    if (!category) return null
    return {
      group_name: group,
      name,
      brand: inferBrand(name),
      price: Math.max(0, Math.round(parseNumber(lookup.get('giá bán')))),
      stock: parseNumber(lookup.get('tồn kho')),
      warranty: normalize(lookup.get('bảo hành')),
      category,
    }
  }).filter((p): p is ImportedProduct => {
    if (!p) return false
    return Boolean(p.group_name && p.name && Number.isFinite(p.price))
  })
}
