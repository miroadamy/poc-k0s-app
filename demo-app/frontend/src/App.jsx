import { useEffect, useState } from "react";

export default function App() {
  const [data, setData] = useState(null);
  const [error, setError] = useState(null);

  const load = async () => {
    try {
      const res = await fetch("/api/hello");
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const json = await res.json();
      setData(json);
      setError(null);
    } catch (err) {
      setError(err.message);
    }
  };

  useEffect(() => {
    load();
  }, []);

  return (
    <div className="page">
      <header>
        <h1>k0s Demo App</h1>
        <p>React frontend + Java backend</p>
      </header>

      <section className="card">
        <h2>Backend response</h2>
        {error && <div className="error">Error: {error}</div>}
        {!error && !data && <div>Loading...</div>}
        {data && <pre>{JSON.stringify(data, null, 2)}</pre>}
        <button onClick={load}>Refresh</button>
      </section>

      <section className="hint">
        <p>
          Hit refresh several times to see load balancing across backend pods.
        </p>
      </section>
    </div>
  );
}
