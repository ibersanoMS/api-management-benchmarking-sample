## Introduction

Benchmark performance testing involves measuring the performance characteristics of an application or system under normal or expected conditions. It's a [recommended practice](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/get-started/performance) in any case, but it's a critical consideration for your APIs since your consumers will depend on consistent performance for their client applications.

Incorporating benchmark testing of your API Management resources into your software delivery process provides several important benefits:

- It establishes performance baseline: It sets a quantifiable baseline against which future results can be compared to detect any performance regressions or improvements.
- It identifies performance bottlenecks: It helps pinpoint changes or integration points that may be causing performance degradation or hindering scalability— in effect helping you to identify which components need to be scaled or configured to maintain performance.  This allows developers and operational staff to make targeted improvements to enhance the performance of your API's.
- It validates performance requirements: By comparing the observed metrics against the specified requirements, you can be assured that the architecture meets the desired operating performance targets.  This can also help you determine a strategy for implementing [throttling](https://learn.microsoft.com/en-us/azure/architecture/patterns/throttling) or a [circuit breaker pattern](https://learn.microsoft.com/en-us/azure/architecture/patterns/circuit-breaker).
- It improves user experience: By identifying and resolving performance issues early in the development life cycle— before your changes make it into production.
- And perhaps most importantly, it gives you the data you need to derive the capacity model you'll need to operate your API's efficiently accross the entire range of design loads.

### Benchmark vs Load Testing. What's the difference?

While the approaches and tools involved are nominally very similar, the reasons for doing them differ. Benchmark testing establishes a performance baseline under normal conditions, while load testing evaluates performance under high scale conditions, often to the point of failure. Benchmark testing sets a reference point for future iterations, while load testing validates scalability and stress handling. Both are important for ensuring API performance, and you can combine the approaches to suit your needs as long as the goals of each are met.

For this post, we're going to focus on the basics of designing a repeatable benchmark test, with a full walkthrough and all the assets you'll need to do it yourself. 

## Model Approach

Before we get into specifics, let's look at the general steps that go into designing your benchmark performance testing strategy.

1. Identify your performance metric: Determine the key performance metric to measure, such as requests per second (RPS), response time, throughput, CPU or memory utilization, network latency, and database performance. The metrics should align with your requirements and objectives. For API Management, and APIs in general, the easiest and most useful metric to gauge is RPS, and it will usually be highly correlated with other measures as a surrogate choice. For that reason, it's the default choice if your circumstances don't guide you to choose a different metric.

The key here is to choose a single metric so that you can make linear comparisons over time. It's possible to devise your own metric based on an aggregation formula, if required, in order to derive the measurement into to a single numeric value.

2. Define your [benchmark](https://en.wikipedia.org/wiki/Benchmark_(computing)) scenario: It should be realistic and represent typical usage patterns and workload conditions. The scenario should reflect the expected behavior of the system in terms of user interactions, data payloads, etc.

Recommendation: Choose an API operation that meets the criteria and is frequently used by your API consumers. Also, make sure that the performance of the scenario is relatively deterministic, meaning that the benchmark measurement would be relatively consistent across repeated measurements using the same code and identical configuration, and not skewed by external or transient conditions.

3. Define the test environment. Whatever method you choose to run the test, just make sure the process is *repeatable*.

Tip: You want your testing environment to satisfy two important things: First, it should be easy. You don't want to deter yourself from following the process by making it tedious or time-consuming. Second, it needs to be consistent across test runs to ensure the results can be compared reliably.

4. Determine how you will record your chosen metric. You may need to instrument your code or API Management service with performance monitoring tools or profiling agents (for example, [Azure Application Insights](https://learn.microsoft.com/en-us/azure/api-management/api-management-howto-app-insights)).

Tip: Be aware that adding observability and instrumentation can, by itself, adversely impact your performance metric, so the ideal case would be a data collection method would be to capture the metric on the client side in your test environment.

5. Execute the test scenario: Run the defined test scenario against the API while measuring the performance metric.
6. Analyze results: Analyze the collected performance data to assess how your API performs. If this isn't your first time running the test, compare the observed performance against the established benchmark to determine if the API continues to meet the desired performance objectives and what the impact (if any) of your code or configuration changes may be.

Example: You just added a policy change that decrypts part of the request payload and transforms it into a different format for your backend to consume. You notice that the RPS metric has dropped from 1100/s to 750/s. Your benchmark objective RPS is 800. Do you revert the change? Do you scale your API management service to compensate? Do you try to optimize your recent changes to see if you can get the results to improve? The bottom line here is that you can use the data to make an informed business decision.

6. Report and document: Document the test results, including performance metrics, observations, and any identified issues or recommended actions. This information serves as a reference for future performance testing iterations and as a new benchmark for future comparison.
7. Iterate and refine. Find ways to automate or optimize the process or modify your strategy as necessary to improve its usefulness to your business operations and decision making.

## Walkthrough

Let's make this more realistic by digging deeper into some implementation details. For the purposes of this walkthrough, we've developed an automated environment setup using Terraform. The environment includes an API Management instance, a basic backend hosted on App Service and an Azure Load Testing resource. We recommend you fork this repository and follow the Instructions in the README to configure your repository to support the GitHub workflow for deployment. The workflow will deploy the infrastructure and then run the load tests for you once.

You can also deploy the Terraform manually. If you choose to deploy the Terraform manually, you will need to follow the instructions below for configuring your load tests through the Portal after the deployment has completed.

  

In the scenario below, we have an API backend hosted on App Service (httpbin) and APIM. As part of our evaluation, we will analyze the backend by itself and then the system as a whole. We will repeat the same set of test cases below for the backend by itself and then the backend with APIM using managed gateway. Azure Load Test is recommended as a testing environment because it doesn't require you to setup JMeter locally to write your own script. Azure Load Test allows you to define parameters, automatically generates the JMeter script for your test and runs it on test engines that spin up on Azure VMs. We used Azure Load Test for our example here.

  

Our test looks at how our API handles small, medium and large payload sizes at an average RPS rate of 500 RPS.

Let's revisit our model approach before we move on:

1. Identify your performance metric: response time. We want to know how long the user will be waiting for a response if the response gets larger.
2. Define your benchmark conditions: Our typical traffic rate is 500 RPS in one region. We will run our tests against one region at a rate of 500 RPS.
3. Define the test environment: Our environment has an App Service with our backend and an APIM instance with one scale unit - both located in the same region. Our Azure Load Test resource is also located in the same Azure region. The GitHub Actions we have setup for deployment and running our load tests makes this process repeatable.
4. Determine how to record your chosen metric: Azure Load Test reports the average response time for each test.
5. Execute the test: Follow the steps below or wait for your deployment pipeline to complete your tests.

  

See below for manual setup and configuration instructions or keep scrolling to see the Results. For the results below, each test case was run three times for additional sample size.

### Setup

Test Configuration

1. Go to the Azure Portal and retrieve your backend URL. Save the value somewhere because you will need it for the next steps. If you're using the sample environment provided, it will be your App Service Hostname URL.
2. Search for Azure Load Testing in the Azure Portal
3. Hit Create in the upper left corner
4. Navigate to Tests
5. Click Create on the upper middle of the window and then Create a URL-based test

    ![create test](./assets/5-create-test.png)
6. Configure the test with the following parameters for your first case (500B payload)

    ![configure test](./assets/6-configure-test.png)
7. Hit Run test

    Once the test completes, you should see results like below:

    ![test results](./assets/7-results.png)
8. Now that we have our baseline test, let's create a test for our medium and large sized payload conditions.

    ![create a new test](./assets/8-create-medium-test.png)
9. Create a new quick test with the following medium-sized payload configuration:

    Hit Run Test.

    Once the test completes, you should see results like below:
    ![test results](./assets/9-test-results.png)


10. Create a new quick test with the following large-sized payload configuration:
it Run Test.

    ![create a large test](./assets/10-large-test.png)

    Once the test completes, you should see results like below:
    
    ![test results](./assets/10-results.png)

> Repeat the above steps for each case using the API URL from your APIM instance.

# Results

Backend Only

500B payload, 500 RPS

|Throughput (RPS)|Average Response Time (ms)|
|---|---|
|444|21|
|431|14|
|447|15|

1000B payload, 500 RPS

|Throughput (RPS)|Average Response Time (ms)|
|---|---|
|425|97|
|432|41|
|428|50.77|

1500B payload, 500 RPS

|Throughput (RPS)|Average Response Time (ms)|
|---|---|
|290|612|
|358|604|
|363|545|

  

APIM + Backend

500B Payload, 500 RPS

|Throughput (RPS)|Average Response Time (ms)|
|---|---|
|443|15|
|441|14|
|436|10|

1,000B Payload, 500 RPS

|Throughput (RPS)|Average Response Time (ms)|
|---|---|
|443|155|
|446|76.55|
|444|70|

1,500B Payload, 500 RPS

|Throughput (RPS)|Average Response Time (ms)|
|---|---|
|361|600|
|370|518|
|367|585|

# Analysis

If we take the average of each three runs for each case, we can plot the response times versus payload size for the backend and the system as a whole. If we look at the chart above, the average response times of the backend are very close to those of the backend by itself. This indicates that under normal load conditions and increasing payload size, introducing APIM into the environment does not have a significant effect on the average response time. If we had noticed that it did have an effect, we could [configure an auto-scale rule](https://learn.microsoft.com/en-us/azure/api-management/api-management-howto-autoscale) in our API Management instance to scale up the number of units when the response time starts to increase beyond a certain value. Auto-scale rules track by the minute. The maximum scale units available depend on your tier: Standard allows 4 total and Premium allows 12 per region.

Another approach would be to manually scale your API Management instance and conduct the load testing again. This would allow you to visibly see the effect of the change on the response time and have confidence that auto-scaling would mitigate the issue before committing to auto scaling.

If you notice that your backend performance is not where you want it to be and placing APIM in front perpetuates the issue, consider scaling your backend to distribute the load and re-run the load tests.

  

Let's revisit our model approach:

6. Analyze results: In the above paragraph, we plotted the average response time for each test case and looked at the backend only versus the system. The plot revealed that there is no significant difference in performance under normal conditions.

7. Report and document:

8. Iterate and refine

  
  
  

Things we need to talk about:

- Every change has a non-trivial effect on the system as a whole
    - Networking
    - Self-hosted vs. managed gateway
    - Monitoring
    - Backend changes
    - Database updates
- Monitoring during load testing
    - Backend hosted on AKS can use Prometheus, Grafana for networking monitoring, etc.