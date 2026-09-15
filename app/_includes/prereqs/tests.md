Before you create a test, you need to create a test suite for the API Collection.

1. If your API Collection doesn't have a **Tests** tab, go to **Preferences** > **General** and enable **Enable Legacy Tests**.
1. On the API Collection screen, click the **Tests** tab.
1. In the sidebar, click **New test suite**.
1. From the test suite you just created, click **New test**. Insomnia creates a default `Return 200` request for you:
   ```javascript
   const response1 = await insomnia.send();
   expect(response1.status).to.equal(200);
   ```
1. From the **Select a request** drop down, select the **GET KongAir planned flights** request.
1. Click the **Play** icon next to your test. In the preview to the right, you should see that the test passes.
