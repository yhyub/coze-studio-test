const core = require('@actions/core');
const http = require('@actions/http-client');

async function run() {
  try {
    const apiKey = core.getInput('api-key');
    const workflowId = core.getInput('workflow-id');
    const inputData = core.getInput('input-data');

    const client = new http.HttpClient('coze-workflow-action');
    const headers = {
      'Authorization': `Bearer ${apiKey}`,
      'Content-Type': 'application/json'
    };

    const requestData = {
      workflow_id: workflowId,
      input: JSON.parse(inputData)
    };

    const response = await client.postJson(
      'https://api.coze.com/v1/workflow/execute',
      requestData,
      headers
    );

    if (response.result && response.result.success) {
      core.setOutput('result', JSON.stringify(response.result.data));
      core.setOutput('status', 'success');
      core.setOutput('execution-time', response.result.execution_time || 0);
    } else {
      core.setFailed(`Workflow execution failed: ${response.result.error.message}`);
    }
  } catch (error) {
    core.setFailed(`Action failed: ${error.message}`);
  }
}

run();