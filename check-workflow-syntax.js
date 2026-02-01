const fs = require('fs');
const path = require('path');

const workflowsDir = path.join(__dirname, '.github', 'workflows');

console.log('Checking workflow file syntax...\n');

function checkFileSyntax(filePath, fileName) {
  try {
    const content = fs.readFileSync(filePath, 'utf8');
    
    // Remove comments (lines starting with #)
    const contentWithoutComments = content.split('\n')
      .map(line => {
        const commentIndex = line.indexOf('#');
        return commentIndex === -1 ? line : line.substring(0, commentIndex);
      })
      .join('\n');
    
    // Handle PowerShell Here-String syntax
    let contentWithoutHereString = contentWithoutComments;
    // Remove @" ... "@ blocks
    contentWithoutHereString = contentWithoutHereString.replace(/@"[\s\S]*?"@/g, '');
    // Remove @' ... '@ blocks
    contentWithoutHereString = contentWithoutHereString.replace(/@'[\s\S]*?'@/g, '');
    
    // Check for common YAML syntax issues
    let valid = true;
    
    // Check for unescaped special characters
    if (contentWithoutHereString.includes('${{') && !contentWithoutHereString.includes('}}')) {
      console.log(`  ✗ Missing closing }} in expression`);
      valid = false;
    }
    
    // Check for mismatched quotes in the entire file
    const singleQuotes = (contentWithoutHereString.match(/'/g) || []).length;
    const doubleQuotes = (contentWithoutHereString.match(/"/g) || []).length;
    if (singleQuotes % 2 !== 0) {
      console.log(`  ✗ Mismatched single quotes in file`);
      valid = false;
    }
    if (doubleQuotes % 2 !== 0) {
      console.log(`  ✗ Mismatched double quotes in file`);
      valid = false;
    }
    
    if (valid) {
      console.log(`  ✓ Syntax check passed`);
    }
    
  } catch (error) {
    console.log(`  ✗ Error reading file: ${error.message}`);
  }
}

try {
  const files = fs.readdirSync(workflowsDir);
  
  files.forEach(file => {
    if (file.endsWith('.yml') || file.endsWith('.yaml')) {
      const filePath = path.join(workflowsDir, file);
      console.log(`Checking ${file}...`);
      
      checkFileSyntax(filePath, file);
      
      console.log();
    }
  });
  
} catch (error) {
  console.error(`Error reading workflows directory: ${error.message}`);
}

console.log('Syntax check complete!');
