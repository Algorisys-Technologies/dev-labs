import { useState } from 'react'
import './app.css'
import Sidebar from './component/sidebar'
import { Outlet } from 'react-router'

function App() {
  const [count, setCount] = useState(0)

  return (
    <div className='container'>
      <div id="sidebar">
        <h2>ERP System</h2>
        <Sidebar />
      </div>
      <div id='main-content'>
        <Outlet />    
      </div>
    </div>
  )
}

export default App
