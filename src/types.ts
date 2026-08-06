export type CategoryKey = 'cpu' | 'mainboard' | 'ram' | 'gpu' | 'ssd' | 'psu' | 'case' | 'cooler' | 'monitor' | 'accessory'

export interface Product {
  id: string
  category: CategoryKey
  group_name?: string
  name: string
  brand: string
  price: number
  image: string
  stock: number
  warranty?: string
  specs: Record<string, string | number | boolean>
}

export type BuildSelection = Partial<Record<CategoryKey, Product>>

export interface ImportedProduct {
  group_name: string
  name: string
  brand: string
  price: number
  stock: number
  warranty: string
  category: CategoryKey
}
