/*
 * Copyright 2026 coze-dev
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import { useState, useEffect, useRef } from 'react'
import { Terminal } from 'xterm'
import { FitAddon } from 'xterm-addon-fit'
import { SearchAddon } from 'xterm-addon-search'
import { WebLinksAddon } from 'xterm-addon-web-links'
import { WebglAddon } from 'xterm-addon-webgl'

interface GitHubTerminalProps {
  repository: string
  branch: string
}

const GitHubTerminal = ({ repository, branch }: GitHubTerminalProps) => {
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const terminalRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    if (!terminalRef.current) return

    // 初始化终端
    const newTerminal = new Terminal({
      cursorBlink: true,
      cursorStyle: 'block',
      fontSize: 12,
      fontFamily: 'Consolas, monospace',
      theme: {
        background: '#012456',
        foreground: '#ffffff',
        cursor: '#ffffff',
        selection: '#ffffff',
        black: '#000000',
        red: '#ff0000',
        green: '#00ff00',
        yellow: '#ffff00',
        blue: '#0000ff',
        magenta: '#ff00ff',
        cyan: '#00ffff',
        white: '#ffffff',
        brightBlack: '#808080',
        brightRed: '#ff6666',
        brightGreen: '#66ff66',
        brightYellow: '#ffff66',
        brightBlue: '#6666ff',
        brightMagenta: '#ff66ff',
        brightCyan: '#66ffff',
        brightWhite: '#e6e6e6'
      }
    })

    const fitAddon = new FitAddon()
    const searchAddon = new SearchAddon()
    const webLinksAddon = new WebLinksAddon()
    const webglAddon = new WebglAddon()

    newTerminal.loadAddon(fitAddon)
    newTerminal.loadAddon(searchAddon)
    newTerminal.loadAddon(webLinksAddon)
    newTerminal.loadAddon(webglAddon)

    newTerminal.open(terminalRef.current)
    fitAddon.fit()

    // 初始化终端内容
    initializeTerminal(newTerminal, repository, branch)

    setIsLoading(false)

    return () => {
      newTerminal.dispose()
    }
  }, [repository, branch])

  const initializeTerminal = (terminal: Terminal, repository: string, branch: string) => {
    terminal.write('GitHub Cloud Terminal')
    terminal.write('\r\n')
    terminal.write('版权所有 (C) GitHub Inc. 保留所有权利。')
    terminal.write('\r\n\r\n')
    terminal.write(`仓库: ${repository}`)
    terminal.write('\r\n')
    terminal.write(`分支: ${branch}`)
    terminal.write('\r\n\r\n')
    terminal.write('尝试新的云终端体验 https://github.com/features/cloud-terminal')
    terminal.write('\r\n\r\n')
    terminal.write('PS C:\\GitHub\\cloud-terminal> ')

    // 处理命令
    terminal.onKey(({ key, domEvent }) => {
      const ev = domEvent as KeyboardEvent
      const printable = !ev.altKey && !ev.ctrlKey && !ev.metaKey

      if (ev.key === 'Enter') {
        terminal.write('\r\n')
        terminal.write('命令执行中...')
        terminal.write('\r\n')
        terminal.write('PS C:\\GitHub\\cloud-terminal> ')
      } else if (ev.key === 'Backspace') {
        terminal.write('\b \b')
      } else if (printable) {
        terminal.write(key)
      }
    })
  }

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-96 bg-gray-900">
        <div className="text-white text-lg">加载终端中...</div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="flex items-center justify-center h-96 bg-gray-900">
        <div className="text-red-500 text-lg">{error}</div>
      </div>
    )
  }

  return (
    <div className="w-full h-full">
      <div 
        ref={terminalRef} 
        className="w-full h-96 bg-gray-900"
      ></div>
    </div>
  )
}

export default GitHubTerminal