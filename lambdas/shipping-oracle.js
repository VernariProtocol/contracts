const baseURL = `https://eth2-beacon-mainnet.nodereal.io/v1/${secrets.apiKey}/eth/v1/beacon/states/head/validator_balances?`;
const trackingNumber = args[0];
const shippingCompany = args[1];
const orderId = args[2];

const apiRequest = Functions.makeHttpRequest({
  url: baseURL,
});

const res = await apiRequest;
if (res.error) {
  throw new Error("Shipping API Error");
}

const trackingStatus = res.data.tracking_status.status;
let statusInt = 0;
if (trackingStatus === "DELIVERED") {
  statusInt = 2;
}

// encode status (uint8), orderNumber (bytes32), company (bytes)

const encoded = abiEncoder.encode(
  ["uint8", "bytes32", "bytes"],
  [(globalTotal * 10 ** 9).toString(), globalCount]
);

return Functions.encodeString(encoded);
