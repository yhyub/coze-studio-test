# Coze AI Workflow Action

A GitHub Action to run AI workflows using the Coze platform.

## Usage

```yaml
- name: Run Coze Workflow
  uses: coze-ai/coze-workflow-action@v1
  with:
    api-key: ${{ secrets.COZE_API_KEY }}
    workflow-id: 'your-workflow-id'
    input-data: '{"input": "your-data"}'
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `api-key` | Coze API Key | Yes | |
| `workflow-id` | Workflow ID to execute | Yes | |
| `input-data` | Input data for the workflow in JSON format | No | `{}` |

## Outputs

| Output | Description |
|--------|-------------|
| `result` | Workflow execution result |
| `status` | Execution status (success/failure) |
| `execution-time` | Execution time in milliseconds |

## License

MIT