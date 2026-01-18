import { useEffect, useState } from "react";

export default function App() {
  const [data, setData] = useState(null);
  const [error, setError] = useState(null);
  const [frontendHostname, setFrontendHostname] = useState("loading...");

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

  const loadFrontendInfo = async () => {
    try {
      const res = await fetch("/api/info");
      if (res.ok) {
        const json = await res.json();
        setFrontendHostname(json.frontend_hostname || "unknown");
      }
    } catch (err) {
      setFrontendHostname("error");
    }
  };

  useEffect(() => {
    loadFrontendInfo();
    load();
  }, []);

  return (
    <div className="page">
      <header>
        <h1>k0s Demo App</h1>
        <p>React frontend + Java backend</p>
      </header>

      <section className="card">
        <h2>Request Chain Identification</h2>
        <div
          style={{
            backgroundColor: "#f5f5f5",
            padding: "10px",
            borderRadius: "4px",
          }}
        >
          <p>
            <strong>Frontend Pod:</strong> {frontendHostname}
          </p>
          {data && (
            <p>
              <strong>Backend Pod:</strong> {data.hostname}
            </p>
          )}
        </div>
      </section>

      <section className="card">
        <h2>Backend response</h2>
        {error && <div className="error">Error: {error}</div>}
        {!error && !data && <div>Loading...</div>}
        {data && <pre>{JSON.stringify(data, null, 2)}</pre>}
        <button onClick={load}>Refresh</button>
      </section>

      <section className="hint">
        <p>
          Hit refresh several times to see:
          <ul>
            <li>Different frontend pods serving the request</li>
            <li>Different backend pods responding to calls</li>
            <li>Load balancing across 4 replicas (2 frontend + 2 backend)</li>
          </ul>
        </p>
      </section>
    </div>
  );
}
