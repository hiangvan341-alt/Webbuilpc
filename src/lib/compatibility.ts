import type { BuildSelection } from '../types'

export interface CompatibilityResult { level: 'ok' | 'warning' | 'error'; message: string }

export function checkCompatibility(build: BuildSelection): CompatibilityResult[] {
  const results: CompatibilityResult[] = []
  const { cpu, mainboard, ram, gpu, psu, case: pcCase, cooler } = build

  if (cpu && mainboard && cpu.specs.socket !== mainboard.specs.socket) {
    results.push({ level:'error', message:`CPU socket ${cpu.specs.socket} không tương thích mainboard socket ${mainboard.specs.socket}.` })
  }
  if (ram && mainboard && ram.specs.ramType !== mainboard.specs.ramType) {
    results.push({ level:'error', message:`RAM ${ram.specs.ramType} không phù hợp mainboard ${mainboard.specs.ramType}.` })
  }
  if (mainboard && pcCase) {
    const mb = String(mainboard.specs.formFactor)
    const cs = String(pcCase.specs.formFactor)
    if (mb === 'ATX' && cs === 'mATX') results.push({ level:'error', message:'Mainboard ATX không lắp vừa case mATX.' })
  }
  if (gpu && pcCase && Number(gpu.specs.length) > Number(pcCase.specs.maxGpuLength)) {
    results.push({ level:'error', message:'Chiều dài VGA vượt quá giới hạn của case.' })
  }
  if (psu) {
    const cpuW = Number(cpu?.specs.tdp || 100)
    const gpuW = Number(gpu?.specs.wattage || 0)
    const recommended = Math.ceil((cpuW + gpuW + 120) * 1.25)
    if (Number(psu.specs.wattage) < recommended) results.push({ level:'warning', message:`Nên dùng nguồn tối thiểu khoảng ${recommended}W cho cấu hình này.` })
  }
  if (cooler && cpu && !String(cooler.specs.sockets).includes(String(cpu.specs.socket))) {
    results.push({ level:'error', message:'Tản nhiệt không hỗ trợ socket CPU đã chọn.' })
  }
  if (!results.length) results.push({ level:'ok', message:'Các linh kiện đã chọn đang tương thích.' })
  return results
}
