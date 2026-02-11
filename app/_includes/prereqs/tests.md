Before you create a test, you need to create a test suite for the collection. 

1. To do this, click the **Tests** tab and click **New test suite** in the sidebar.
1. From the Test Suite you just created, click **New test**. Insomnia creates a default `Return 200` request for you:
   ```javascript
   const response1 = await insomnia.send();
   expect(response1.status).to.equal(200);
   ```
1. From the **Select a request** drop down, select the **GET KongAir planned flights** request.
1. Click the **Play** icon next to your test. In the preview to the right, you should see that the test passes.