import React, { useState } from 'react'

function App() {
  const [isScanning, setIsScanning] = useState(false)
  const [results, setResults] = useState([])
  const [logs, setLogs] = useState('')

  const runScan = async () => {
    setIsScanning(true)
    setResults([])
    setLogs('')

    try {
      // 这里应该调用后端API或执行扫描脚本
      // 暂时模拟扫描过程
      setLogs('开始安全扫描...\n')
      
      // 模拟扫描结果
      const mockResults = [
        { type: 'info', title: '扫描开始', message: '2024-01-28 10:00:00' },
        { type: 'info', title: '找到 5 个已安装的Actions', message: '正在逐一扫描...' },
        { type: 'warn', title: 'Action "actions/checkout" 使用动态版本 "latest"', message: '建议使用固定版本' },
        { type: 'info', title: 'Action "actions/setup-node" 使用固定版本 "v4"', message: '安全状态良好' },
        { type: 'error', title: 'Action "unknown/action" 来源不合法', message: '不在允许列表中' },
        { type: 'info', title: '扫描完成', message: '共 5 个Actions，其中 2 个存在安全问题' }
      ]

      setResults(mockResults)
      setLogs('扫描完成\n')
    } catch (error) {
      setResults([{ type: 'error', title: '扫描失败', message: error.message }])
      setLogs(`扫描失败: ${error.message}\n`)
    } finally {
      setIsScanning(false)
    }
  }

  return (
    <div className="app">
      <header className="header">
        <h1>GitHub Action 安全扫描</h1>
        <p>检查GitHub Actions的安全状态，确保使用固定版本和合法来源</p>
      </header>

      <section className="scan-section">
        <h2>运行安全扫描</h2>
        <button 
          className="scan-button" 
          onClick={runScan} 
          disabled={isScanning}
        >
          {isScanning ? '扫描中...' : '开始扫描'}
        </button>
      </section>

      {results.length > 0 && (
        <section className="results-section">
          <h2>扫描结果</h2>
          {results.map((result, index) => (
            <div key={index} className={`result-item ${result.type}`}>
              <h3>{result.title}</h3>
              <p>{result.message}</p>
            </div>
          ))}
        </section>
      )}

      {logs && (
        <section className="logs-section">
          <h2>扫描日志</h2>
          <div className="logs-content">
            <pre>{logs}</pre>
          </div>
        </section>
      )}
    </div>
  )
}

export default App