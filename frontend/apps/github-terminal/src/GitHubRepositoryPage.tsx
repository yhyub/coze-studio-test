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
import { useState } from 'react'
import GitHubTerminal from './GitHubIntegration'

interface GitHubRepositoryPageProps {
  repository: string
  owner: string
  branch: string
}

const GitHubRepositoryPage: React.FC<GitHubRepositoryPageProps> = ({ repository, owner, branch }) => {
  const [activeTab, setActiveTab] = useState('code')

  const tabs = [
    { id: 'code', title: '代码', count: null },
    { id: 'issues', title: '问题', count: 428 },
    { id: 'pulls', title: '拉取请求', count: 23 },
    { id: 'actions', title: '行动', count: null },
    { id: 'projects', title: '项目', count: null },
    { id: 'wiki', title: '维基百科', count: null },
    { id: 'security', title: '安全', count: null },
    { id: 'insights', title: '见解', count: null },
    { id: 'terminal', title: '终端', count: null }
  ]

  const renderTabContent = () => {
    switch (activeTab) {
      case 'code':
        return (
          <div className="p-4">
            <h2 className="text-xl font-bold mb-4">代码</h2>
            <p>仓库代码内容将显示在这里</p>
          </div>
        )
      case 'issues':
        return (
          <div className="p-4">
            <h2 className="text-xl font-bold mb-4">问题</h2>
            <p>问题列表将显示在这里</p>
          </div>
        )
      case 'pulls':
        return (
          <div className="p-4">
            <h2 className="text-xl font-bold mb-4">拉取请求</h2>
            <p>拉取请求列表将显示在这里</p>
          </div>
        )
      case 'terminal':
        return (
          <div className="p-4">
            <h2 className="text-xl font-bold mb-4">终端</h2>
            <div className="border border-gray-700 rounded-md overflow-hidden">
              <GitHubTerminal repository={`${owner}/${repository}`} branch={branch} />
            </div>
          </div>
        )
      default:
        return (
          <div className="p-4">
            <h2 className="text-xl font-bold mb-4">{tabs.find(t => t.id === activeTab)?.title}</h2>
            <p>内容将显示在这里</p>
          </div>
        )
    }
  }

  return (
    <div className="min-h-screen bg-gray-100">
      {/* GitHub 头部 */}
      <header className="bg-gray-800 text-white">
        <div className="container mx-auto px-4 py-3 flex items-center justify-between">
          <div className="flex items-center space-x-4">
            <div className="font-bold text-lg">GitHub</div>
            <div className="text-sm">{owner} / {repository}</div>
          </div>
          <div className="flex items-center space-x-4">
            <button className="bg-blue-600 hover:bg-blue-700 px-3 py-1 rounded text-sm">
              分叉
            </button>
            <button className="bg-green-600 hover:bg-green-700 px-3 py-1 rounded text-sm">
              星标
            </button>
          </div>
        </div>
      </header>

      {/* 仓库导航栏 */}
      <nav className="bg-gray-900 text-white border-b border-gray-700">
        <div className="container mx-auto px-4">
          <div className="flex items-center space-x-1 overflow-x-auto">
            {tabs.map(tab => (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`px-3 py-2 text-sm font-medium flex items-center space-x-1 whitespace-nowrap ${
                  activeTab === tab.id 
                    ? 'bg-gray-800 border-b-2 border-blue-500' 
                    : 'hover:bg-gray-800'
                }`}
              >
                <span>{tab.title}</span>
                {tab.count !== null && (
                  <span className="bg-gray-700 rounded-full px-2 py-0.5 text-xs">
                    {tab.count}
                  </span>
                )}
              </button>
            ))}
          </div>
        </div>
      </nav>

      {/* 分支选择器 */}
      <div className="bg-gray-100 border-b border-gray-200 py-2 px-4">
        <div className="container mx-auto flex items-center space-x-2">
          <div className="flex items-center space-x-1">
            <span className="text-sm font-medium">分支:</span>
            <button className="bg-white border border-gray-300 rounded px-2 py-1 text-sm flex items-center space-x-1">
              <span>{branch}</span>
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
              </svg>
            </button>
          </div>
          <button className="bg-white border border-gray-300 rounded px-2 py-1 text-sm">
            <svg className="w-4 h-4 mr-1 inline" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
            </svg>
            添加文件
          </button>
          <button className="bg-white border border-gray-300 rounded px-2 py-1 text-sm">
            <svg className="w-4 h-4 mr-1 inline" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4" />
            </svg>
            上传文件
          </button>
        </div>
      </div>

      {/* 主内容 */}
      <main className="container mx-auto px-4 py-6">
        {renderTabContent()}
      </main>

      {/* 页脚 */}
      <footer className="bg-gray-100 border-t border-gray-200 py-6">
        <div className="container mx-auto px-4">
          <div className="flex items-center justify-between">
            <div className="text-sm text-gray-600">
              © 2026 GitHub, Inc.
            </div>
            <div className="flex items-center space-x-4">
              <a href="#" className="text-sm text-gray-600 hover:text-gray-900">
                条款
              </a>
              <a href="#" className="text-sm text-gray-600 hover:text-gray-900">
                隐私
              </a>
              <a href="#" className="text-sm text-gray-600 hover:text-gray-900">
                安全
              </a>
              <a href="#" className="text-sm text-gray-600 hover:text-gray-900">
                联系 GitHub
              </a>
            </div>
          </div>
        </div>
      </footer>
    </div>
  )
}

export default GitHubRepositoryPage