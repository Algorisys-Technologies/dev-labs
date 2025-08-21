import { Routes, Route, Link } from "react-router-dom";
import RuleBuilder from "./components/RuleBuilder";

export default function App() {
  return (
    <div className="p-6">
      <nav className="mb-6">
        <Link to="/" className="text-blue-600">Rule Builder</Link>
      </nav>
      <Routes>
        <Route path="/" element={<RuleBuilder />} />
      </Routes>
    </div>
  );
}
