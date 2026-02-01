import requests
import argparse
import time

def delete_workflow_runs(repo_owner, repo_name, github_token, workflow_id=None, days=30):
    """
    删除GitHub Actions工作流运行记录
    
    Args:
        repo_owner: 仓库所有者
        repo_name: 仓库名称
        github_token: GitHub个人访问令牌
        workflow_id: 工作流ID（可选）
        days: 删除多少天前的记录（默认30天）
    """
    headers = {
        "Authorization": f"token {github_token}",
        "Accept": "application/vnd.github.v3+json"
    }
    
    # 计算截止日期
    cutoff_date = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime(time.time() - days * 86400))
    
    # 获取工作流运行记录
    if workflow_id:
        url = f"https://api.github.com/repos/{repo_owner}/{repo_name}/actions/workflows/{workflow_id}/runs"
    else:
        url = f"https://api.github.com/repos/{repo_owner}/{repo_name}/actions/runs"
    
    runs_deleted = 0
    page = 1
    
    while True:
        params = {
            "per_page": 100,
            "page": page,
            "created": f"<{cutoff_date}"
        }
        
        response = requests.get(url, headers=headers, params=params)
        response.raise_for_status()
        
        runs = response.json().get("workflow_runs", [])
        
        if not runs:
            break
        
        for run in runs:
            run_id = run["id"]
            run_name = run["name"]
            run_created = run["created_at"]
            
            print(f"删除运行记录: {run_name} (ID: {run_id}, 创建时间: {run_created})")
            
            # 删除运行记录
            delete_url = f"https://api.github.com/repos/{repo_owner}/{repo_name}/actions/runs/{run_id}"
            delete_response = requests.delete(delete_url, headers=headers)
            
            if delete_response.status_code == 204:
                print(f"  ✅ 成功删除运行记录 {run_id}")
                runs_deleted += 1
                # 避免API速率限制
                time.sleep(0.5)
            else:
                print(f"  ❌ 删除失败: {delete_response.status_code} - {delete_response.text}")
        
        page += 1
    
    print(f"\n删除完成，共删除 {runs_deleted} 条运行记录")

def main():
    parser = argparse.ArgumentParser(description="删除GitHub Actions运行记录")
    parser.add_argument("--owner", required=True, help="仓库所有者")
    parser.add_argument("--repo", required=True, help="仓库名称")
    parser.add_argument("--token", required=True, help="GitHub个人访问令牌")
    parser.add_argument("--workflow", help="工作流ID")
    parser.add_argument("--days", type=int, default=30, help="删除多少天前的记录")
    
    args = parser.parse_args()
    
    delete_workflow_runs(
        repo_owner=args.owner,
        repo_name=args.repo,
        github_token=args.token,
        workflow_id=args.workflow,
        days=args.days
    )

if __name__ == "__main__":
    main()