import { useState } from 'react'
import reactLogo from './assets/react.svg'
import viteLogo from '/vite.svg'
import './App.css'
import PurchaseUI from './component/PurchaseUI'

function App() {
  const [count, setCount] = useState(0)

  return (
    <>
      
       <PurchaseUI/>

    </>
  )
}

export default App
