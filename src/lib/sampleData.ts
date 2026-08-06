import type { CategoryKey, Product } from '../types'

export const categories: { key: CategoryKey; label: string; shortLabel: string; required: boolean; order: number }[] = [
  { key: 'cpu', label: 'CPU - Bộ vi xử lý', shortLabel: 'CPU', required: true, order: 1 },
  { key: 'mainboard', label: 'Mainboard - Bo mạch chủ', shortLabel: 'Mainboard', required: true, order: 2 },
  { key: 'ram', label: 'RAM - Bộ nhớ', shortLabel: 'RAM', required: true, order: 3 },
  { key: 'gpu', label: 'VGA - Card đồ họa', shortLabel: 'VGA', required: false, order: 4 },
  { key: 'ssd', label: 'SSD / HDD - Ổ cứng', shortLabel: 'Ổ cứng', required: true, order: 5 },
  { key: 'psu', label: 'PSU - Nguồn máy tính', shortLabel: 'Nguồn', required: true, order: 6 },
  { key: 'case', label: 'Case - Vỏ máy tính', shortLabel: 'Case', required: true, order: 7 },
  { key: 'cooler', label: 'Tản nhiệt CPU', shortLabel: 'Tản nhiệt', required: false, order: 8 },
  { key: 'monitor', label: 'Màn hình', shortLabel: 'Màn hình', required: false, order: 9 },
  { key: 'accessory', label: 'Phụ kiện và Gear', shortLabel: 'Phụ kiện', required: false, order: 10 },
]

export const categoryOrder = Object.fromEntries(categories.map(c => [c.key, c.order])) as Record<CategoryKey, number>

const img = (seed: string) => `https://images.unsplash.com/photo-1587202372775-e229f172b9d7?auto=format&fit=crop&w=500&q=70&sig=${seed}`

export const sampleProducts: Product[] = [
  { id:'cpu-amd-7600', category:'cpu', name:'AMD Ryzen 5 7600', brand:'AMD', price:4890000, image:img('1'), stock:12, specs:{ socket:'AM5', tdp:65, ramType:'DDR5' } },
  { id:'cpu-intel-14400f', category:'cpu', name:'Intel Core i5-14400F', brand:'Intel', price:5290000, image:img('2'), stock:9, specs:{ socket:'LGA1700', tdp:148, ramType:'DDR4/DDR5' } },
  { id:'mb-b650m', category:'mainboard', name:'MSI PRO B650M-B', brand:'MSI', price:2690000, image:img('3'), stock:8, specs:{ socket:'AM5', ramType:'DDR5', formFactor:'mATX' } },
  { id:'mb-b760m-ddr4', category:'mainboard', name:'ASUS PRIME B760M-K D4', brand:'ASUS', price:2590000, image:img('4'), stock:11, specs:{ socket:'LGA1700', ramType:'DDR4', formFactor:'mATX' } },
  { id:'ram-ddr5-32', category:'ram', name:'Kingston Fury Beast 32GB DDR5 6000', brand:'Kingston', price:2490000, image:img('5'), stock:20, specs:{ ramType:'DDR5', capacity:32 } },
  { id:'ram-ddr4-32', category:'ram', name:'Corsair Vengeance LPX 32GB DDR4 3200', brand:'Corsair', price:1890000, image:img('6'), stock:15, specs:{ ramType:'DDR4', capacity:32 } },
  { id:'gpu-5060', category:'gpu', name:'Gigabyte GeForce RTX 5060 8GB', brand:'Gigabyte', price:10490000, image:img('7'), stock:6, specs:{ wattage:145, length:280 } },
  { id:'gpu-rx7600', category:'gpu', name:'Sapphire Radeon RX 7600 8GB', brand:'Sapphire', price:7490000, image:img('8'), stock:7, specs:{ wattage:165, length:240 } },
  { id:'ssd-1tb', category:'ssd', name:'WD Blue SN580 1TB NVMe', brand:'Western Digital', price:1690000, image:img('9'), stock:30, specs:{ capacity:1000, interface:'NVMe' } },
  { id:'psu-650', category:'psu', name:'Cooler Master MWE 650 Bronze V2', brand:'Cooler Master', price:1490000, image:img('10'), stock:13, specs:{ wattage:650, certification:'80 Plus Bronze' } },
  { id:'psu-750', category:'psu', name:'Corsair RM750e 750W Gold', brand:'Corsair', price:2690000, image:img('11'), stock:10, specs:{ wattage:750, certification:'80 Plus Gold' } },
  { id:'case-air100', category:'case', name:'Montech AIR 100 ARGB', brand:'Montech', price:1290000, image:img('12'), stock:14, specs:{ formFactor:'mATX', maxGpuLength:330 } },
  { id:'case-atx', category:'case', name:'NZXT H5 Flow', brand:'NZXT', price:2190000, image:img('13'), stock:5, specs:{ formFactor:'ATX', maxGpuLength:365 } },
  { id:'cooler-ak400', category:'cooler', name:'DeepCool AK400', brand:'DeepCool', price:690000, image:img('14'), stock:17, specs:{ sockets:'AM5,LGA1700', tdpSupport:220 } },
  { id:'monitor-24', category:'monitor', name:'AOC 24G4 24 inch 180Hz', brand:'AOC', price:3290000, image:img('15'), stock:16, specs:{ size:24, refreshRate:180 } }
]
