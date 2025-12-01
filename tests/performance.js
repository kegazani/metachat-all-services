const http = require('http');
const { performance } = require('k6');

// Configuration
const USER_SERVICE_URL = 'http://localhost:8081';
const DIARY_SERVICE_URL = 'http://localhost:8082';
const CONCURRENT_USERS = 10;
const REQUESTS_PER_USER = 20;
const TEST_DURATION_SECONDS = 30;

// Test scenarios
const testScenarios = [
  {
    name: 'User Registration',
    path: '/users',
    method: 'POST',
    payload: {
      username: `testuser_${Date.now()}`,
      email: `testuser_${Date.now()}@example.com`,
      firstName: 'Test',
      lastName: 'User',
      dateOfBirth: '1990-01-01'
    }
  },
  {
    name: 'User Profile Update',
    path: '/users/{id}/profile',
    method: 'PUT',
    payload: {
      firstName: 'Updated',
      lastName: 'User',
      bio: 'Updated bio for performance testing'
    }
  },
  {
    name: 'Diary Entry Creation',
    path: '/diary/entries',
    method: 'POST',
    payload: {
      userId: '{userId}',
      title: 'Performance Test Entry',
      content: 'This is a performance test diary entry.',
      tokenCount: 100,
      sessionId: `perf-session-${Date.now()}`
    }
  },
  {
    name: 'Get User',
    path: '/users/{id}',
    method: 'GET'
  },
  {
    name: 'Get Diary Entries',
    path: '/diary/entries/user/{userId}',
    method: 'GET'
  },
  {
    name: 'Get Diary Entry',
    path: '/diary/entries/{id}',
    method: 'GET'
  }
];

// Performance metrics
let metrics = {
  requests: 0,
  errors: 0,
  responseTimes: [],
  minResponseTime: Infinity,
  maxResponseTime: 0,
  averageResponseTime: 0,
  p95ResponseTime: 0,
  p99ResponseTime: 0,
  requestsPerSecond: 0,
  errorsPerSecond: 0
};

// HTTP client
const client = http.defaultAgent({ keepAlive: true, keepAliveMsecs: 5000 });

// Test runner
async function runTest(scenario) {
  const startTime = Date.now();
  
  try {
    const response = await client({
      method: scenario.method,
      url: scenario.path.includes('{id}') 
        ? scenario.path.replace('{id}', scenario.userId) 
        : scenario.path,
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(scenario.payload)
    });
    
    const endTime = Date.now();
    const responseTime = endTime - startTime;
    
    // Update metrics
    metrics.requests++;
    metrics.responseTimes.push(responseTime);
    metrics.minResponseTime = Math.min(metrics.minResponseTime, responseTime);
    metrics.maxResponseTime = Math.max(metrics.maxResponseTime, responseTime);
    metrics.averageResponseTime = metrics.responseTimes.reduce((sum, time) => sum + time, 0) / metrics.responseTimes.length;
    metrics.p95ResponseTime = calculatePercentile(metrics.responseTimes, 0.95);
    metrics.p99ResponseTime = calculatePercentile(metrics.responseTimes, 0.99);
    
    // Calculate requests per second
    const requestsPerSecond = metrics.requests / (TEST_DURATION_SECONDS / 1000);
    metrics.requestsPerSecond = Math.max(metrics.requestsPerSecond, requestsPerSecond);
    
    // Calculate errors per second
    const errorsPerSecond = metrics.errors / (TEST_DURATION_SECONDS / 1000);
    metrics.errorsPerSecond = Math.max(metrics.errorsPerSecond, errorsPerSecond);
    
    // Log result
    console.log(`Scenario: ${scenario.name}`);
    console.log(`Status: ${response.status}`);
    console.log(`Response Time: ${responseTime}ms`);
    
    if (response.status >= 200 && response.status < 300) {
      console.log('✅ Success');
    } else {
      console.log('❌ Failed');
      metrics.errors++;
    }
    
    // Add delay between requests
    await new Promise(resolve => setTimeout(resolve, 100));
  } catch (error) {
    console.error(`Error: ${error.message}`);
    metrics.errors++;
  }
}

// Calculate percentile
function calculatePercentile(values, percentile) {
  const sorted = values.slice().sort((a, b) => a - b);
  const index = Math.floor(percentile / 100 * sorted.length);
  return sorted[index];
}

// Run all tests
async function runAllTests() {
  console.log('Starting performance tests...');
  console.log(`Target: ${CONCURRENT_USERS} concurrent users`);
  console.log(`Requests per user: ${REQUESTS_PER_USER}`);
  console.log(`Test duration: ${TEST_DURATION_SECONDS} seconds`);
  
  // Reset metrics
  metrics = {
    requests: 0,
    errors: 0,
    responseTimes: [],
    minResponseTime: Infinity,
    maxResponseTime: 0,
    averageResponseTime: 0,
    p95ResponseTime: 0,
    p99ResponseTime: 0,
    requestsPerSecond: 0,
    errorsPerSecond: 0
  };
  
  // Run tests sequentially with some concurrency
  const promises = [];
  for (let i = 0; i < testScenarios.length; i++) {
    for (let j = 0; j < CONCURRENT_USERS; j++) {
      promises.push(runTest(testScenarios[i]));
    }
    // Small delay between batches
    await new Promise(resolve => setTimeout(resolve, 50));
  }
  
  // Wait for all tests to complete
  await Promise.all(promises);
  
  // Calculate final metrics
  const totalTime = Date.now() - startTime;
  const totalRequests = metrics.requests;
  const totalErrors = metrics.errors;
  const avgResponseTime = metrics.averageResponseTime;
  const p95ResponseTime = metrics.p95ResponseTime;
  const p99ResponseTime = metrics.p99ResponseTime;
  const requestsPerSecond = totalRequests / (totalTime / 1000);
  const errorsPerSecond = totalErrors / (totalTime / 1000);
  
  console.log('\n=== Performance Test Results ===');
  console.log(`Total Requests: ${totalRequests}`);
  console.log(`Total Errors: ${totalErrors}`);
  console.log(`Average Response Time: ${avgResponseTime.toFixed(2)}ms`);
  console.log(`95th Percentile Response Time: ${p95ResponseTime.toFixed(2)}ms`);
  console.log(`99th Percentile Response Time: ${p99ResponseTime.toFixed(2)}ms`);
  console.log(`Requests per Second: ${requestsPerSecond.toFixed(2)}`);
  console.log(`Errors per Second: ${errorsPerSecond.toFixed(2)}`);
  console.log(`Total Test Time: ${(totalTime / 1000).toFixed(2)}s`);
  
  // Performance evaluation
  if (avgResponseTime < 100) {
    console.log('✅ Performance: Excellent');
  } else if (avgResponseTime < 200) {
    console.log('✅ Performance: Good');
  } else if (avgResponseTime < 500) {
    console.log('✅ Performance: Acceptable');
  } else {
    console.log('⚠️ Performance: Needs Improvement');
  }
  
  // Check error rate
  const errorRate = (totalErrors / totalRequests) * 100;
  if (errorRate < 1) {
    console.log('✅ Error Rate: Excellent (< 1%)');
  } else if (errorRate < 5) {
    console.log('✅ Error Rate: Good (< 5%)');
  } else {
    console.log('⚠️ Error Rate: High (> 5%)');
  }
  
  // Check throughput
  const throughput = (totalRequests / totalTime) * 1000;
  console.log(`Throughput: ${throughput.toFixed(2)} requests/second`);
  
  // Check if we met our target
  if (requestsPerSecond >= REQUESTS_PER_USER) {
    console.log('✅ Target Met: >= ${REQUESTS_PER_USER} requests/second');
  } else {
    console.log('⚠️ Target Not Met: < ${REQUESTS_PER_USER} requests/second');
  }
}

// Run the tests
runAllTests().catch(error => {
  console.error('Test execution failed:', error);
  process.exit(1);
});