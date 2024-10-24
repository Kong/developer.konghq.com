---
title: Example Insomnia Scripts
content_type: reference
layout: reference

related_resources:
  - text: Insomnia Testing
    url: /insomnia/test
  - text: Chain Requests
    url: /how_tos/chain-requests

products:
    - insomnia
---



## Request 
Provided are some common snippets that can be helpful when interacting with your APIs visa Insomnia. 


### Set and unset variables

```
insomnia.environment.get("variable_key");
insomnia.globals.get("variable_key");
insomnia.variables.get("variable_key");
insomnia.collectionVariables.get("variable_key");
insomnia.environment.set("variable_key", "variable_value");
insomnia.globals.set("variable_key", "variable_value");
insomnia.collectionVariables.set("variable_key", "variable_value");
insomnia.environment.unset("variable_key");
insomnia.globals.unset("variable_key");
insomnia.collectionVariables.unset("variable_key");
```

## Response

### Headers




### Test status codes

```
insomnia.test("Status code is 201", () => {
  insomnia.response.to.have.status(201);
});
```

```
  insomnia.test("Successful POST request", () => {
  insomnia.expect(insomnia.response.code).to.be.oneOf([201,202]);
});
```

```
  insomnia.test("Status code error name", () => {
  insomnia.response.to.have.status("Bad Request");
});

```

### Test Response bodies

```
/* Response contains flight details:
{
	"aircraft_type": "Boeing 777",
	"flight_number": "KA0284",
	"in_flight_entertainment": true,
	"meal_options": [
		"Chicken",
		"Fish",
		"Vegetarian"
	]
}
*/
const jsonData = insomnia.response.json();
insomnia.test("Test data type of the response", () => {
  insomnia.expect(jsonData).to.be.an("object");
  insomnia.expect(jsonData.aircraft_type).to.be.a("string");
  insomnia.expect(jsonData.in_flight_entertainment).to.be.a("boolean");
  insomnia.expect(jsonData.meal_options).to.be.an("array");
});
```

```
const jsonData= insomnia.response.json();
insomnia.test("Test response properties", () => {
  insomnia.expect(jsonData.aircraft_type).to.include("Boeing 777");
});
```

### Test response times


```
  insomnia.test("Response time is less than 50ms", () => {
  insomnia.expect(insomnia.response.responseTime).to.be.below(50);
});
```