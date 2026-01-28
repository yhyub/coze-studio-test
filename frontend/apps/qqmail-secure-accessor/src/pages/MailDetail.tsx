import React, { useState, useEffect } from 'react';
import { useParams, Link, useNavigate } from 'react-router-dom';
import { ArrowLeft, Reply, Forward, Archive, Trash2, Star, AlertCircle, Download, Copy, ExternalLink } from '@heroicons/react/24/outline';

interface MailDetail {
  id: number;
  subject: string;
  from: string;
  fromName: string;
  to: string;
  toName: string;
  date: string;
  content: string;
  attachments: Array<{
    id: string;
    name: string;
    size: string;
    type: string;
  }>;
  isImportant: boolean;
  isStarred: boolean;
  headers: Record<string, string>;
}

const MailDetail: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const [mail, setMail] = useState<MailDetail | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [showHeaders, setShowHeaders] = useState(false);

  useEffect(() => {
    const fetchMailDetail = async () => {
      setIsLoading(true);
      // 模拟网络请求延迟
      await new Promise(resolve => setTimeout(resolve, 1000));

      // 模拟邮件详情数据
      const mockMailDetail: MailDetail = {
        id: parseInt(id || '1'),
        subject: '[yhyub/yhyub-yfdxg] Run failed: Data Fetch - master (6295919)',
        from: 'notifications@github.com',
        fromName: 'GitHub',
        to: 'user@qq.com',
        toName: 'QQ用户',
        date: '2026-01-28 14:30:00',
        content: `
          <div class="markdown-body">
            <h1>Run failed: Data Fetch - master (6295919)</h1>
            <p>Build failed in 2m 34s</p>
            <h2>Details</h2>
            <ul>
              <li>Repository: yhyub/yhyub-yfdxg</li>
              <li>Branch: master</li>
              <li>Commit: 6295919</li>
              <li>Workflow: Data Fetch</li>
            </ul>
            <h2>Error message</h2>
            <pre><code>Error: Failed to fetch data from API
    at fetchData (src/utils/api.js:42:15)
    at processTicksAndRejections (node:internal/process/task_queues:95:5)
    at async run (src/workflows/data-fetch.js:18:20)</code></pre>
            <h2>Steps</h2>
            <ol>
              <li>Checkout code - ✅</li>
              <li>Install dependencies - ✅</li>
              <li>Run tests - ✅</li>
              <li>Fetch data - ❌</li>
              <li>Deploy - ⏭️</li>
            </ol>
            <h2>Actions</h2>
            <p>You can view the full build log <a href="https://github.com/yhyub/yhyub-yfdxg/actions/runs/123456" target="_blank">here</a>.</p>
          </div>
        `,
        attachments: [
          {
            id: '1',
            name: 'build-log.txt',
            size: '2.5 KB',
            type: 'text/plain'
          },
          {
            id: '2',
            name: 'error-screenshot.png',
            size: '1.2 MB',
            type: 'image/png'
          }
        ],
        isImportant: false,
        isStarred: false,
        headers: {
          'Received': 'from smtp.github.com (smtp.github.com [192.30.252.194]) by mx.qq.com with ESMTPS id',
          'DKIM-Signature': 'v=1; a=rsa-sha256; c=relaxed/relaxed; d=github.com; s=github;',
          'Subject': '[yhyub/yhyub-yfdxg] Run failed: Data Fetch - master (6295919)',
          'From': 'GitHub <notifications@github.com>',
          'To': 'user@qq.com',
          'Date': 'Wed, 28 Jan 2026 14:30:00 +0800',
          'Message-ID': '<yhyub/yhyub-yfdxg/actions/runs/123456@github.com>',
          'MIME-Version': '1.0',
          'Content-Type': 'multipart/alternative; boundary="--==_mimepart_60a1b2c3d4e5f6"',
          'Content-Transfer-Encoding': '7bit'
        }
      };

      setMail(mockMailDetail);
      setIsLoading(false);
    };

    fetchMailDetail();
  }, [id]);

  const toggleStarStatus = () => {
    if (mail) {
      setMail({ ...mail, isStarred: !mail.isStarred });
    }
  };

  const toggleImportantStatus = () => {
    if (mail) {
      setMail({ ...mail, isImportant: !mail.isImportant });
    }
  };

  const handleDownloadAttachment = (attachmentId: string) => {
    // 模拟下载附件
    console.log(`Downloading attachment ${attachmentId}`);
  };

  const handleCopyContent = () => {
    if (mail) {
      const textContent = mail.content.replace(/<[^>]*>/g, '');
      navigator.clipboard.writeText(textContent);
      alert('邮件内容已复制到剪贴板');
    }
  };

  if (isLoading) {
    return (
      <div className="card p-8 text-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600 mx-auto"></div>
        <p className="mt-4 text-gray-600">加载邮件详情中...</p>
      </div>
    );
  }

  if (!mail) {
    return (
      <div className="card p-8 text-center">
        <ArrowLeft className="h-12 w-12 text-gray-300 mx-auto" />
        <p className="mt-4 text-gray-600">邮件不存在或已被删除</p>
        <Link
          to="/mail/list"
          className="mt-4 inline-flex items-center text-sm font-medium text-primary-600 hover:text-primary-500"
        >
          返回邮件列表
        </Link>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* 导航栏 */}
      <div className="flex items-center space-x-4">
        <button
          onClick={() => navigate('/mail/list')}
          className="btn btn-secondary flex items-center"
        >
          <ArrowLeft className="h-4 w-4 mr-1" />
          返回列表
        </button>
        <h1 className="text-2xl font-bold text-gray-900">邮件详情</h1>
      </div>

      {/* 邮件头部信息 */}
      <div className="card">
        <div className="p-6 border-b border-gray-200">
          <div className="flex items-start justify-between">
            <h2 className="text-xl font-bold text-gray-900">{mail.subject}</h2>
            <div className="flex items-center space-x-2">
              <button
                onClick={toggleStarStatus}
                className={`p-2 rounded-full ${mail.isStarred ? 'text-yellow-500 bg-yellow-50' : 'text-gray-400 hover:bg-gray-100'}`}
                aria-label={mail.isStarred ? '取消星标' : '标记为星标'}
              >
                <Star className="h-5 w-5" />
              </button>
              <button
                onClick={toggleImportantStatus}
                className={`p-2 rounded-full ${mail.isImportant ? 'text-yellow-500 bg-yellow-50' : 'text-gray-400 hover:bg-gray-100'}`}
                aria-label={mail.isImportant ? '取消重要标记' : '标记为重要'}
              >
                <AlertCircle className="h-5 w-5" />
              </button>
            </div>
          </div>
        </div>

        <div className="p-6">
          <div className="space-y-4">
            <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between">
              <div>
                <p className="text-sm font-medium text-gray-900">发件人</p>
                <p className="mt-1 text-sm text-gray-600">
                  {mail.fromName} &lt;{mail.from}&gt;
                </p>
              </div>
              <div>
                <p className="text-sm font-medium text-gray-900">收件人</p>
                <p className="mt-1 text-sm text-gray-600">
                  {mail.toName} &lt;{mail.to}&gt;
                </p>
              </div>
              <div>
                <p className="text-sm font-medium text-gray-900">日期</p>
                <p className="mt-1 text-sm text-gray-600">{mail.date}</p>
              </div>
            </div>

            {/* 邮件操作按钮 */}
            <div className="flex flex-wrap items-center gap-2 pt-4 border-t border-gray-200">
              <button className="btn btn-secondary flex items-center">
                <Reply className="h-4 w-4 mr-1" />
                回复
              </button>
              <button className="btn btn-secondary flex items-center">
                <Forward className="h-4 w-4 mr-1" />
                转发
              </button>
              <button className="btn btn-secondary flex items-center">
                <Archive className="h-4 w-4 mr-1" />
                存档
              </button>
              <button className="btn btn-secondary flex items-center text-red-600 hover:text-red-700 hover:bg-red-50">
                <Trash2 className="h-4 w-4 mr-1" />
                删除
              </button>
              <button className="btn btn-secondary flex items-center">
                <Copy className="h-4 w-4 mr-1" />
                复制
              </button>
              <button
                onClick={() => setShowHeaders(!showHeaders)}
                className="btn btn-secondary flex items-center"
              >
                {showHeaders ? '隐藏邮件头' : '显示邮件头'}
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* 邮件内容 */}
      <div className="card">
        <div className="p-6">
          <h3 className="text-lg font-medium text-gray-900 mb-4">邮件内容</h3>
          <div 
            className="prose max-w-none"
            dangerouslySetInnerHTML={{ __html: mail.content }}
          />
        </div>
      </div>

      {/* 邮件头信息 */}
      {showHeaders && (
        <div className="card">
          <div className="p-6">
            <h3 className="text-lg font-medium text-gray-900 mb-4">邮件头信息</h3>
            <div className="bg-gray-50 rounded-md p-4 font-mono text-sm">
              {Object.entries(mail.headers).map(([key, value]) => (
                <div key={key} className="mb-2">
                  <span className="font-bold text-primary-600">{key}:</span> {value}
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* 附件 */}
      {mail.attachments.length > 0 && (
        <div className="card">
          <div className="p-6">
            <h3 className="text-lg font-medium text-gray-900 mb-4">附件 ({mail.attachments.length})</h3>
            <div className="space-y-3">
              {mail.attachments.map((attachment) => (
                <div
                  key={attachment.id}
                  className="flex items-center justify-between p-3 bg-gray-50 rounded-md"
                >
                  <div className="flex items-center space-x-3">
                    <div className="p-2 bg-blue-100 rounded-md">
                      <Download className="h-5 w-5 text-blue-600" />
                    </div>
                    <div>
                      <p className="text-sm font-medium text-gray-900">{attachment.name}</p>
                      <p className="text-xs text-gray-500">{attachment.size} • {attachment.type}</p>
                    </div>
                  </div>
                  <button
                    onClick={() => handleDownloadAttachment(attachment.id)}
                    className="btn btn-secondary flex items-center text-sm"
                  >
                    <Download className="h-3 w-3 mr-1" />
                    下载
                  </button>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default MailDetail;