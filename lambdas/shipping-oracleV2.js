const baseURL = `https://api.goshippo.com/tracks/`;
const trackingNumber = args[0];
const shippingCompany = args[1];
const orderId = args[2];
const url = `${baseURL}${shippingCompany}/${trackingNumber}`;

const apiRequest = Functions.makeHttpRequest({
  url: url,
  headers: {
    Authorization: `ShippoToken ${secrets.shippoKey}`,
  },
});

const res = await apiRequest;
if (res.error) {
  throw new Error("Shipping API Error");
}

const trackingStatus = res.data.tracking_status.status;
console.log(trackingStatus);
let statusInt = 0;
if (trackingStatus === "DELIVERED") {
  statusInt = 2;
}

const integerBuffer = Buffer.alloc(4);
integerBuffer.writeInt32BE(statusInt);
const paddedBuffer = Buffer.alloc(32);
integerBuffer.copy(paddedBuffer, 32 - 4);

const hexBuffer = Buffer.from(orderId, "hex");
const buf = Buffer.concat([paddedBuffer, hexBuffer]);
return buf;
