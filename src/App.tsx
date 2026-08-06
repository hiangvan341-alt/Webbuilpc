import { useEffect, useMemo, useState } from 'react'
import type { FormEvent } from 'react'
import { CheckCircle2, ChevronRight, FileSpreadsheet, Grid2X2, KeyRound, List, LogIn, LogOut, Pencil, Plus, Printer, RefreshCw, Rows3, RotateCcw, Save, Share2, ShieldCheck, ShoppingCart, Trash2, Upload, User, UserPlus, X } from 'lucide-react'
import { categories, categoryOrder, sampleProducts } from './lib/sampleData'
import { checkCompatibility } from './lib/compatibility'
import { getProducts, rpc, supabaseConfigured } from './lib/supabase'
import { parseProductWorkbook } from './lib/importExcel'
import type { BuildSelection, CategoryKey, ImportedProduct, Product } from './types'

type QuoteSettings={company_name:string;hotline:string;email:string;address:string;website:string;notice:string;thank_you:string}
type UserAccountRow={id:string;username:string;is_active:boolean;created_at:string;last_login_at:string|null}

const money = (n:number) => new Intl.NumberFormat('vi-VN').format(n) + ' đ'
const today = () => new Intl.DateTimeFormat('vi-VN', { dateStyle: 'short', timeStyle: 'medium' }).format(new Date())
const defaultQuote:QuoteSettings={company_name:'CÔNG TY TNHH CÔNG NGHỆ NOVA TECH PC',hotline:'0377 455 855',email:'contact@novatechpc.vn',address:'134 Nguyễn Chính - Hoàng Mai - HN',website:'Novatechpc.vn',notice:'Giá bán, khuyến mãi của sản phẩm và tình trạng còn hàng có thể thay đổi bất cứ lúc nào mà không kịp báo trước.',thank_you:'NOVA TECH PC CHÂN THÀNH CẢM ƠN QUÝ KHÁCH'}
const emptyImage = 'https://placehold.co/400x300/f5f7fa/667085?text=Nova+Tech+PC'

function dbToProduct(p:any):Product {
  return { id:p.id, category:p.category, group_name:p.group_name, name:p.name, brand:p.brand || '', price:Number(p.sale_price ?? p.price ?? 0), image:p.image_url || emptyImage, stock:Number(p.stock || 0), warranty:p.warranty || '', specs:p.specs || {} }
}

export default function App(){
  const [build, setBuild] = useState<BuildSelection>({})
  const [active, setActive] = useState<CategoryKey | null>(null)
  const [search, setSearch] = useState('')
  const [brandFilter, setBrandFilter] = useState('')
  const [stockOnly, setStockOnly] = useState(true)
  const [minPrice, setMinPrice] = useState('')
  const [maxPrice, setMaxPrice] = useState('')
  const [sortBy, setSortBy] = useState<'recommended'|'price-asc'|'price-desc'|'name'>('recommended')
  const [budget, setBudget] = useState(30000000)
  const [products, setProducts] = useState<Product[]>(sampleProducts)
  const [adminOpen, setAdminOpen] = useState(false)
  const [quoteOpen, setQuoteOpen] = useState(false)
  const [userOpen,setUserOpen]=useState(false)
  const [viewMode,setViewMode]=useState<'grid'|'columns'|'rows'>('grid')
  const [quoteSettings,setQuoteSettings]=useState<QuoteSettings>(defaultQuote)

  useEffect(()=>{
    if (!supabaseConfigured) return
    rpc<QuoteSettings[]>('get_quote_settings',{}).then(r=>r?.[0]&&setQuoteSettings(r[0])).catch(console.warn)
    getProducts<any[]>().then(rows=>rows.length && setProducts(rows.map(dbToProduct).sort((a,b)=>categoryOrder[a.category]-categoryOrder[b.category] || a.name.localeCompare(b.name,'vi')))).catch(console.warn)
  },[])

  const total = (Object.values(build) as Array<Product | undefined>).reduce((s,p)=>s+(p?.price||0),0)
  const compatibility = useMemo(()=>checkCompatibility(build),[build])
  const categoryProducts = useMemo(()=>products.filter(p=>p.category===active),[products,active])
  const brands = useMemo(()=>Array.from(new Set(categoryProducts.map(p=>p.brand).filter(Boolean))).sort((a,b)=>a.localeCompare(b,'vi')),[categoryProducts])
  const filtered = useMemo(()=>categoryProducts
    .filter(p=>p.name.toLowerCase().includes(search.toLowerCase()))
    .filter(p=>!brandFilter || p.brand===brandFilter)
    .filter(p=>!stockOnly || p.stock>0)
    .filter(p=>!minPrice || p.price>=Number(minPrice))
    .filter(p=>!maxPrice || p.price<=Number(maxPrice))
    .sort((a,b)=>{
      if(sortBy==='price-asc') return a.price-b.price
      if(sortBy==='price-desc') return b.price-a.price
      if(sortBy==='name') return a.name.localeCompare(b.name,'vi')
      return Number(b.stock>0)-Number(a.stock>0) || b.stock-a.stock || a.price-b.price || a.name.localeCompare(b.name,'vi')
    }),[categoryProducts,search,brandFilter,stockOnly,minPrice,maxPrice,sortBy])
  const categoryCounts = useMemo(()=>Object.fromEntries(categories.map(c=>[c.key,products.filter(p=>p.category===c.key).length])) as Record<CategoryKey,number>,[products])
  const requiredDone = categories.filter(c=>c.required).every(c=>build[c.key])

  function openCategory(category:CategoryKey){ setActive(category); setSearch(''); setBrandFilter(''); setStockOnly(true); setMinPrice(''); setMaxPrice(''); setSortBy('recommended') }
  function choose(p:Product){ setBuild(v=>({...v,[p.category]:p})); setActive(null); setSearch('') }
  function remove(category:CategoryKey){ setBuild(v=>{const n={...v}; delete n[category]; return n}) }
  function reset(){ if(confirm('Xóa toàn bộ linh kiện đã chọn?')) setBuild({}) }
  function share(){ navigator.clipboard.writeText(location.href + '#build=' + btoa(JSON.stringify(Object.fromEntries(Object.entries(build).map(([k,v])=>[k,v?.id]))))); alert('Đã sao chép liên kết cấu hình.') }
  function save(){ localStorage.setItem('pc-builder-draft',JSON.stringify(build)); alert('Đã lưu cấu hình trên trình duyệt.') }

  return <div className="app">
    <header className="topbar">
      <div className="brand"><img src="/nova-tech-logo.png"/><div><b>NOVA TECH PC</b><span>Đối tác cho sự thành công của bạn</span></div></div>
      <nav><a href="#builder">Build PC</a><a href="#guide">Hướng dẫn</a><button className="user-login" onClick={()=>setUserOpen(true)}><User size={16}/> Đăng nhập</button><button className="admin" onClick={()=>setAdminOpen(true)}><LogIn size={16}/> Quản trị</button></nav>
    </header>

    <section className="hero">
      <div><span className="eyebrow">CÔNG CỤ XÂY DỰNG CẤU HÌNH</span><h1>Tự chọn linh kiện,<br/>kiểm tra tương thích tức thì</h1><p>Dữ liệu sản phẩm được cập nhật trực tiếp từ file Excel của NOVA TECH PC.</p></div>
      <div className="budget-card"><label>Ngân sách dự kiến</label><strong>{money(budget)}</strong><input type="range" min="7000000" max="100000000" step="1000000" value={budget} onChange={e=>setBudget(+e.target.value)}/><div className="budget-status">Đã chọn {money(total)} • Còn lại {money(Math.max(0,budget-total))}</div></div>
    </section>

    <main id="builder" className="layout">
      <section className="builder-panel">
        <div className="panel-head"><div><h2>Xây dựng cấu hình PC</h2><p>Chọn lần lượt từng nhóm linh kiện</p></div><button className="ghost" onClick={reset}><RotateCcw size={17}/> Làm mới</button></div>
        <div className="parts-list">
          {categories.map((c,i)=>{const p=build[c.key]; return <div className="part-row" key={c.key}>
            <div className="part-index">{i+1}</div>
            <div className="part-info"><div className="part-label">{c.label} {c.required&&<span>*</span>}</div>{p?<div className="selected"><img src={p.image}/><div><b>{p.name}</b><small>{p.warranty || 'Chưa có thông tin bảo hành'} • Tồn {p.stock}</small></div><strong>{money(p.price)}</strong><button onClick={()=>remove(c.key)}><X size={18}/></button></div>:<button className="select-btn" onClick={()=>openCategory(c.key)}><span>+ Chọn linh kiện <small>{categoryCounts[c.key]||0} sản phẩm</small></span><ChevronRight size={18}/></button>}</div>
          </div>})}
        </div>
      </section>

      <aside className="summary">
        <h3>Tóm tắt cấu hình</h3>
        <div className="sum-line"><span>Chi phí linh kiện</span><b>{money(total)}</b></div>
        <div className="sum-line"><span>Phí lắp ráp</span><b>Miễn phí</b></div>
        <div className="total"><span>Tổng thanh toán</span><strong>{money(total)}</strong></div>
        <div className="compat"><h4><ShieldCheck size={18}/> Kiểm tra tương thích</h4>{compatibility.map((r,i)=><div key={i} className={'notice '+r.level}><CheckCircle2 size={16}/><span>{r.message}</span></div>)}</div>
        <button className="primary" disabled={!requiredDone}><ShoppingCart size={19}/> Gửi yêu cầu đặt hàng</button>
        <button className="quote-button" disabled={!Object.keys(build).length} onClick={()=>setQuoteOpen(true)}><Printer size={18}/> Xem/In báo giá</button>
        <div className="actions"><button onClick={save}><Save size={17}/> Lưu</button><button onClick={share}><Share2 size={17}/> Chia sẻ</button></div>
        {!requiredDone&&<small className="hint">Hãy chọn đủ CPU, Mainboard, RAM, ổ cứng, nguồn và case.</small>}
      </aside>
    </main>

    <section id="guide" className="features"><article><FileSpreadsheet/><h3>Nhập Excel nhanh</h3><p>Admin chỉ cần tải file có 5 cột: Nhóm hàng, Tên hàng, Giá bán, Tồn kho và Bảo hành.</p></article><article><ShieldCheck/><h3>Kiểm tra tương thích</h3><p>Kiểm tra socket CPU, chuẩn RAM, công suất nguồn, kích thước VGA và case.</p></article><article><Printer/><h3>Báo giá NOVA TECH PC</h3><p>Tự tạo bảng báo giá theo mẫu công ty và in trực tiếp từ trình duyệt.</p></article></section>

    {active&&<div className="modal-backdrop" onClick={()=>setActive(null)}><div className="modal" onClick={e=>e.stopPropagation()}><div className="modal-head"><div><h2>{categories.find(c=>c.key===active)?.label}</h2><p>{categoryProducts.length} sản phẩm đã được phân loại vào đúng danh mục</p></div><button onClick={()=>setActive(null)}><X/></button></div>
      <div className="catalog-tools"><input className="search" placeholder="Tìm theo tên sản phẩm..." value={search} onChange={e=>setSearch(e.target.value)}/><select value={brandFilter} onChange={e=>setBrandFilter(e.target.value)}><option value="">Tất cả thương hiệu</option>{brands.map(b=><option key={b}>{b}</option>)}</select><input type="number" min="0" placeholder="Giá từ" value={minPrice} onChange={e=>setMinPrice(e.target.value)}/><input type="number" min="0" placeholder="Giá đến" value={maxPrice} onChange={e=>setMaxPrice(e.target.value)}/><select value={sortBy} onChange={e=>setSortBy(e.target.value as typeof sortBy)}><option value="recommended">Ưu tiên còn hàng</option><option value="price-asc">Giá thấp đến cao</option><option value="price-desc">Giá cao đến thấp</option><option value="name">Tên A-Z</option></select><label className="stock-check"><input type="checkbox" checked={stockOnly} onChange={e=>setStockOnly(e.target.checked)}/> Chỉ còn hàng</label></div>
      <div className="filter-result"><span>Đang hiển thị <b>{filtered.length}</b> / {categoryProducts.length} sản phẩm</span><div className="view-switch"><button className={viewMode==='grid'?'active':''} onClick={()=>setViewMode('grid')} title="Lưới"><Grid2X2 size={17}/><span>Lưới</span></button><button className={viewMode==='columns'?'active':''} onClick={()=>setViewMode('columns')} title="Cột gọn"><List size={17}/><span>Cột</span></button><button className={viewMode==='rows'?'active':''} onClick={()=>setViewMode('rows')} title="Hàng ngang"><Rows3 size={17}/><span>Hàng ngang</span></button></div></div><div className={`product-grid ${viewMode}`}> {filtered.map(p=><article className="product" key={p.id}><img src={p.image}/><div className={'stock '+(p.stock<=0?'out':'')}>{p.stock>0?`Còn ${p.stock}`:'Hết hàng'}</div><div className="group-tag">{p.group_name || categories.find(c=>c.key===p.category)?.shortLabel}</div><h3>{p.name}</h3><p>{p.warranty || 'Bảo hành: đang cập nhật'}</p><strong>{money(p.price)}</strong><button disabled={p.stock<=0} onClick={()=>choose(p)}>{p.stock>0?'Chọn sản phẩm':'Tạm hết hàng'}</button></article>)}</div>{!filtered.length&&<div className="empty">Không có sản phẩm phù hợp với bộ lọc hiện tại.</div>}</div></div>}
    {userOpen&&<UserLogin onClose={()=>setUserOpen(false)}/>}
    {adminOpen&&<AdminPanel quoteSettings={quoteSettings} onQuoteSaved={setQuoteSettings} onClose={()=>setAdminOpen(false)} onImported={()=>getProducts<any[]>().then(rows=>setProducts(rows.map(dbToProduct).sort((a,b)=>categoryOrder[a.category]-categoryOrder[b.category] || a.name.localeCompare(b.name,'vi'))))}/>} 
    {quoteOpen&&<Quote settings={quoteSettings} build={build} total={total} onClose={()=>setQuoteOpen(false)}/>} 
  </div>
}

function AdminPanel({onClose,onImported,quoteSettings,onQuoteSaved}:{onClose:()=>void,onImported:()=>void,quoteSettings:QuoteSettings,onQuoteSaved:(v:QuoteSettings)=>void}){
  const [token,setToken]=useState(()=>sessionStorage.getItem('nova-admin-token')||'')
  const [username,setUsername]=useState(()=>localStorage.getItem('nova-admin-user')||'admin')
  const [password,setPassword]=useState('')
  const [status,setStatus]=useState('')
  const [rows,setRows]=useState<ImportedProduct[]>([])
  const [fileName,setFileName]=useState('')
  const [newUser,setNewUser]=useState('')
  const [newPass,setNewPass]=useState('')
  const [newCustomer,setNewCustomer]=useState('')
  const [newCustomerPass,setNewCustomerPass]=useState('')
  const [quoteForm,setQuoteForm]=useState<QuoteSettings>(quoteSettings)
  const [rememberAdmin,setRememberAdmin]=useState(()=>localStorage.getItem('nova-admin-user')!==null)
  const [users,setUsers]=useState<UserAccountRow[]>([])
  const [editingUserId,setEditingUserId]=useState('')
  const [editingUsername,setEditingUsername]=useState('')
  const [resetPasswordUserId,setResetPasswordUserId]=useState('')
  const [resetPasswordValue,setResetPasswordValue]=useState('')

  async function login(e:FormEvent){e.preventDefault();setStatus('Đang đăng nhập...');try{const result=await rpc<{token:string}[]>('admin_login',{p_username:username,p_password:password});const t=result?.[0]?.token;if(!t)throw new Error('Sai tài khoản hoặc mật khẩu');sessionStorage.setItem('nova-admin-token',t);if(rememberAdmin)localStorage.setItem('nova-admin-user',username);else localStorage.removeItem('nova-admin-user');setToken(t);setPassword('');setStatus('Đăng nhập thành công');await loadUsers(t)}catch(err){setStatus('Đăng nhập thất bại: '+String(err))}}
  async function loadUsers(adminToken=token){if(!adminToken)return;try{const data=await rpc<UserAccountRow[]>('admin_list_user_accounts',{p_token:adminToken});setUsers(data||[])}catch(err){setStatus('Không tải được danh sách người dùng: '+String(err))}}
  useEffect(()=>{if(token)loadUsers(token)},[token])
  async function pick(file?:File){if(!file)return;setStatus('Đang đọc Excel...');try{const data=await parseProductWorkbook(file);setRows(data);setFileName(file.name);setStatus(`Đã đọc ${data.length} sản phẩm. Chưa ghi vào hệ thống.`)}catch(err){setStatus('Không đọc được file: '+String(err))}}
  async function importNow(){if(!rows.length)return;setStatus('Đang nhập dữ liệu lên Supabase...');try{await rpc('admin_import_products',{p_token:token,p_rows:rows});setStatus(`Đã cập nhật ${rows.length} sản phẩm.`);onImported()}catch(err){setStatus('Nhập dữ liệu thất bại: '+String(err))}}
  async function createCustomer(e:FormEvent){e.preventDefault();setStatus('Đang tạo tài khoản người dùng...');try{await rpc('admin_create_user_account',{p_token:token,p_username:newCustomer,p_password:newCustomerPass});setStatus(`Đã tạo tài khoản người dùng ${newCustomer}.`);setNewCustomer('');setNewCustomerPass('');await loadUsers()}catch(err){setStatus('Không tạo được tài khoản người dùng: '+String(err))}}
  async function saveUserName(userId:string){if(!editingUsername.trim())return;try{await rpc('admin_update_user_account',{p_token:token,p_user_id:userId,p_username:editingUsername,p_is_active:null});setEditingUserId('');setStatus('Đã cập nhật tên tài khoản.');await loadUsers()}catch(err){setStatus('Không sửa được tài khoản: '+String(err))}}
  async function toggleUser(user:UserAccountRow){try{await rpc('admin_update_user_account',{p_token:token,p_user_id:user.id,p_username:null,p_is_active:!user.is_active});setStatus(user.is_active?'Đã khóa tài khoản.':'Đã mở khóa tài khoản.');await loadUsers()}catch(err){setStatus('Không đổi được trạng thái: '+String(err))}}
  async function resetUserPassword(userId:string){if(resetPasswordValue.length<6){setStatus('Mật khẩu mới phải có ít nhất 6 ký tự.');return}try{await rpc('admin_reset_user_password',{p_token:token,p_user_id:userId,p_new_password:resetPasswordValue});setResetPasswordUserId('');setResetPasswordValue('');setStatus('Đã cấp mật khẩu mới. Mật khẩu cũ không còn hiệu lực.')}catch(err){setStatus('Không cấp được mật khẩu mới: '+String(err))}}
  async function deleteUser(user:UserAccountRow){if(!confirm(`Xóa tài khoản ${user.username}? Các phiên đăng nhập của tài khoản này cũng sẽ bị xóa.`))return;try{await rpc('admin_delete_user_account',{p_token:token,p_user_id:user.id});setStatus('Đã xóa tài khoản người dùng.');await loadUsers()}catch(err){setStatus('Không xóa được tài khoản: '+String(err))}}
  async function saveQuote(e:FormEvent){e.preventDefault();setStatus('Đang lưu mẫu báo giá...');try{await rpc('admin_update_quote_settings',{p_token:token,p_settings:quoteForm});onQuoteSaved(quoteForm);setStatus('Đã lưu thông tin mẫu báo giá.')}catch(err){setStatus('Không lưu được mẫu báo giá: '+String(err))}}
  async function createAccount(e:FormEvent){e.preventDefault();setStatus('Đang tạo tài khoản...');try{await rpc('admin_create_account',{p_token:token,p_username:newUser,p_password:newPass});setStatus(`Đã tạo tài khoản ${newUser}.`);setNewUser('');setNewPass('')}catch(err){setStatus('Không tạo được: '+String(err))}}
  function logout(){sessionStorage.removeItem('nova-admin-token');setToken('');setPassword('')}

  return <div className="modal-backdrop"><div className="admin-panel"><div className="modal-head"><div><h2>Quản trị NOVA TECH PC</h2><p>Nhập sản phẩm Excel, quản lý admin và toàn bộ tài khoản người dùng</p></div><button onClick={onClose}><X/></button></div>
    {!token?<form className="login-form" onSubmit={login}><label>Tên đăng nhập<input autoComplete="username" value={username} onChange={e=>setUsername(e.target.value)} required/></label><label>Mật khẩu<input type="password" autoComplete="current-password" value={password} onChange={e=>setPassword(e.target.value)} required/></label><label className="remember-login"><input type="checkbox" checked={rememberAdmin} onChange={e=>setRememberAdmin(e.target.checked)}/> Ghi nhớ tên đăng nhập. Trình duyệt có thể đề nghị lưu mật khẩu.</label><button className="primary"><LogIn size={18}/> Đăng nhập</button><small>Tài khoản ban đầu: <b>admin</b> • Mật khẩu: <b>Do12345</b>. Nên tạo tài khoản mới và đổi thông tin sau lần đăng nhập đầu tiên.</small></form>:<div className="admin-body">
      <div className="admin-toolbar"><span>Đã đăng nhập quản trị</span><button onClick={logout}><LogOut size={16}/> Đăng xuất</button></div>
      <section className="admin-card"><h3><Upload size={19}/> Nhập danh sách sản phẩm</h3><p>Web chỉ đọc đúng 5 cột: <b>Nhóm hàng(3 Cấp), Tên hàng, Giá bán, Tồn kho, Bảo hành</b>.</p><label className="upload-box"><input type="file" accept=".xlsx,.xls" onChange={e=>pick(e.target.files?.[0])}/><FileSpreadsheet size={28}/><b>{fileName||'Chọn hoặc kéo file Excel vào đây'}</b><span>Hỗ trợ .xlsx và .xls</span></label>{rows.length>0&&<><div className="import-summary"><b>{rows.length}</b> sản phẩm • <b>{new Set(rows.map(r=>r.group_name)).size}</b> nhóm Excel • <b>{new Set(rows.map(r=>r.category)).size}</b> danh mục web</div><div className="preview-table"><table><thead><tr><th>Danh mục web</th><th>Nhóm hàng Excel</th><th>Tên hàng</th><th>Giá bán</th><th>Tồn</th><th>Bảo hành</th></tr></thead><tbody>{rows.slice(0,8).map((r,i)=><tr key={i}><td>{categories.find(c=>c.key===r.category)?.shortLabel}</td><td>{r.group_name}</td><td>{r.name}</td><td>{money(r.price)}</td><td>{r.stock}</td><td>{r.warranty}</td></tr>)}</tbody></table></div><button className="primary" onClick={importNow}><Upload size={18}/> Cập nhật vào hệ thống</button></>}</section>
<section className="admin-card"><h3><UserPlus size={19}/> Quản lý tài khoản người dùng</h3><p>Admin có thể xem toàn bộ user, sửa tên đăng nhập, khóa/mở khóa, cấp mật khẩu mới hoặc xóa. Hệ thống không hiển thị mật khẩu hiện tại.</p><form className="account-form" onSubmit={createCustomer}><input autoComplete="off" placeholder="Tên tài khoản người dùng" value={newCustomer} onChange={e=>setNewCustomer(e.target.value)} minLength={3} required/><input type="password" autoComplete="new-password" placeholder="Mật khẩu (tối thiểu 6 ký tự)" value={newCustomerPass} onChange={e=>setNewCustomerPass(e.target.value)} minLength={6} required/><button><Plus size={17}/> Tạo người dùng</button></form><div className="user-list-head"><b>{users.length} tài khoản người dùng</b><button type="button" onClick={()=>loadUsers()}><RefreshCw size={15}/> Làm mới</button></div><div className="user-admin-table"><table><thead><tr><th>Tên tài khoản</th><th>Trạng thái</th><th>Ngày tạo</th><th>Đăng nhập gần nhất</th><th>Thao tác</th></tr></thead><tbody>{users.map(user=><tr key={user.id}><td>{editingUserId===user.id?<div className="inline-edit"><input value={editingUsername} onChange={e=>setEditingUsername(e.target.value)} minLength={3}/><button onClick={()=>saveUserName(user.id)}><Save size={15}/></button><button onClick={()=>setEditingUserId('')}><X size={15}/></button></div>:<b>{user.username}</b>}</td><td><button className={user.is_active?'status-pill active':'status-pill locked'} onClick={()=>toggleUser(user)}>{user.is_active?'Đang hoạt động':'Đã khóa'}</button></td><td>{new Date(user.created_at).toLocaleString('vi-VN')}</td><td>{user.last_login_at?new Date(user.last_login_at).toLocaleString('vi-VN'):'Chưa đăng nhập'}</td><td><div className="user-actions"><button title="Sửa tên" onClick={()=>{setEditingUserId(user.id);setEditingUsername(user.username)}}><Pencil size={15}/></button><button title="Cấp mật khẩu mới" onClick={()=>{setResetPasswordUserId(user.id);setResetPasswordValue('')}}><KeyRound size={15}/></button><button className="danger" title="Xóa tài khoản" onClick={()=>deleteUser(user)}><Trash2 size={15}/></button></div>{resetPasswordUserId===user.id&&<div className="password-reset"><input type="password" autoComplete="new-password" placeholder="Mật khẩu mới" value={resetPasswordValue} onChange={e=>setResetPasswordValue(e.target.value)}/><button onClick={()=>resetUserPassword(user.id)}>Cấp lại</button><button onClick={()=>setResetPasswordUserId('')}>Hủy</button></div>}</td></tr>)}</tbody></table>{!users.length&&<div className="no-users">Chưa có tài khoản người dùng.</div>}</div></section>
      <section className="admin-card quote-settings"><h3><Printer size={19}/> Chỉnh sửa mẫu báo giá</h3><form onSubmit={saveQuote}><label>Tên công ty<input value={quoteForm.company_name} onChange={e=>setQuoteForm({...quoteForm,company_name:e.target.value})}/></label><div className="two-fields"><label>Hotline<input value={quoteForm.hotline} onChange={e=>setQuoteForm({...quoteForm,hotline:e.target.value})}/></label><label>Email<input value={quoteForm.email} onChange={e=>setQuoteForm({...quoteForm,email:e.target.value})}/></label></div><label>Địa chỉ<input value={quoteForm.address} onChange={e=>setQuoteForm({...quoteForm,address:e.target.value})}/></label><label>Website<input value={quoteForm.website} onChange={e=>setQuoteForm({...quoteForm,website:e.target.value})}/></label><label>Lưu ý báo giá<textarea value={quoteForm.notice} onChange={e=>setQuoteForm({...quoteForm,notice:e.target.value})}/></label><label>Lời cảm ơn<input value={quoteForm.thank_you} onChange={e=>setQuoteForm({...quoteForm,thank_you:e.target.value})}/></label><button className="primary"><Save size={17}/> Lưu mẫu báo giá</button></form></section>
      <section className="admin-card"><h3><UserPlus size={19}/> Tạo tài khoản admin</h3><p>Không hiển thị hoặc đọc lại mật khẩu của bất kỳ tài khoản admin nào.</p><form className="account-form" onSubmit={createAccount}><input placeholder="Tên tài khoản" value={newUser} onChange={e=>setNewUser(e.target.value)} minLength={3} required/><input type="password" placeholder="Mật khẩu (tối thiểu 6 ký tự)" value={newPass} onChange={e=>setNewPass(e.target.value)} minLength={6} required/><button><Plus size={17}/> Tạo tài khoản</button></form></section>
    </div>}
    {status&&<div className="admin-status">{status}</div>}
  </div></div>
}

function UserLogin({onClose}:{onClose:()=>void}){
  const [username,setUsername]=useState(()=>localStorage.getItem('nova-user-name')||'');const [password,setPassword]=useState('');const [remember,setRemember]=useState(Boolean(localStorage.getItem('nova-user-name')));const [status,setStatus]=useState('')
  async function login(e:FormEvent){e.preventDefault();setStatus('Đang đăng nhập...');try{const r=await rpc<{token:string}[]>('user_login',{p_username:username,p_password:password});if(!r?.[0]?.token)throw new Error('Sai tài khoản hoặc mật khẩu');localStorage.setItem('nova-user-token',r[0].token);if(remember)localStorage.setItem('nova-user-name',username);else localStorage.removeItem('nova-user-name');setPassword('');setStatus('Đăng nhập thành công.')}catch(err){setStatus('Đăng nhập thất bại: '+String(err))}}
  return <div className="modal-backdrop"><div className="login-dialog"><div className="modal-head"><div><h2>Đăng nhập người dùng</h2><p>Tài khoản do quản trị viên NOVA TECH PC cấp</p></div><button onClick={onClose}><X/></button></div><form className="login-form" onSubmit={login}><label>Tên đăng nhập<input autoComplete="username" value={username} onChange={e=>setUsername(e.target.value)} required/></label><label>Mật khẩu<input type="password" autoComplete="current-password" value={password} onChange={e=>setPassword(e.target.value)} required/></label><label className="remember-login"><input type="checkbox" checked={remember} onChange={e=>setRemember(e.target.checked)}/> Ghi nhớ tên đăng nhập. Trình duyệt có thể đề nghị lưu mật khẩu.</label><button className="primary"><LogIn size={18}/> Đăng nhập</button>{status&&<div className="admin-status">{status}</div>}</form></div></div>
}

function Quote({settings,build,total,onClose}:{settings:QuoteSettings,build:BuildSelection,total:number,onClose:()=>void}){
  const items=Object.values(build).filter(Boolean) as Product[]
  return <div className="modal-backdrop quote-backdrop"><div className="quote-shell"><div className="quote-actions"><button onClick={onClose}><X size={17}/> Đóng</button><button className="primary-inline" onClick={()=>window.print()}><Printer size={17}/> In báo giá</button></div><article className="quotation">
    <header className="quote-header"><div><h3>{settings.company_name}</h3><p><b>Trụ sở:</b> {settings.address}</p><p><b>Hotline:</b> {settings.hotline} &nbsp; | &nbsp; <b>Email:</b> {settings.email}</p><p><b>Website:</b> {settings.website}</p></div><img src="/nova-tech-logo.png"/></header><div className="green-line"/><h1>BÁO GIÁ SẢN PHẨM</h1><div className="quote-meta"><span>Ngày báo giá: <b>{today()}</b></span><span>Đơn vị tính: <b>VNĐ</b></span></div>
    <table><thead><tr><th>STT</th><th>TÊN SẢN PHẨM</th><th>BẢO HÀNH</th><th>SỐ LƯỢNG</th><th>ĐƠN GIÁ</th><th>THÀNH TIỀN</th></tr></thead><tbody>{items.map((p,i)=><tr key={p.id}><td>{i+1}</td><td>{p.name}</td><td>{p.warranty||'Theo chính sách NSX'}</td><td>1</td><td>{new Intl.NumberFormat('vi-VN').format(p.price)}</td><td>{new Intl.NumberFormat('vi-VN').format(p.price)}</td></tr>)}{Array.from({length:Math.max(0,8-items.length)}).map((_,i)=><tr key={'blank'+i}><td>&nbsp;</td><td></td><td></td><td></td><td></td><td></td></tr>)}</tbody><tfoot><tr><td colSpan={4} rowSpan={4} className="quote-note"></td><td>Phí vận chuyển</td><td>0</td></tr><tr><td>Chi phí khác</td><td>0</td></tr><tr><td>Tổng tiền đơn hàng</td><td>{new Intl.NumberFormat('vi-VN').format(total)}</td></tr><tr className="grand"><td>TỔNG THANH TOÁN</td><td>{new Intl.NumberFormat('vi-VN').format(total)} VNĐ</td></tr></tfoot></table>
    <p className="customer-note"><b>Quý khách lưu ý:</b> {settings.notice}</p><footer><span>Để biết thêm chi tiết, vui lòng liên hệ<br/><b>Hotline: {settings.hotline}</b> (8h00 - 21h00 hàng ngày)</span><b>{settings.thank_you}</b></footer>
  </article></div></div>
}
