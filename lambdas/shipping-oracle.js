function encodeValue(types, value) {
  if (types.length !== value.length) {
    throw new Error("Invalid value");
  }
  const encoder = new TextEncoder();
  let encodedValue = "";
  let v;
  let padded;

  for (let i = 0; i < types.length; i++) {
    console.log(types[i], value[i]);
    switch (types[i]) {
      case "string":
        encodedValue = encodedValue.concat(padNumber(value.length * 32));
        encodedValue = encodedValue.concat(padNumber(value[i].length));
        v = Array.from(encoder.encode(value[i]))
          .map((b) => b.toString(16).padStart(2, "0"))
          .join("");
        padded = "0".repeat(64 - v.length);
        encodedValue = encodedValue.concat(v + padded);
        break;
      case "uint":
        if (!Number.isInteger(value[i])) {
          throw new Error("Invalid uint value");
        }
        v = BigInt(value[i]).toString(16).padStart(32, "0");
        padded = "0".repeat(64 - v.length);
        encodedValue = encodedValue.concat(padded + v);
        break;
      case "bool":
        let buf = new ArrayBuffer(1);
        const dataView = new DataView(buf);
        dataView.setUint8(0, value[i] ? 1 : 0);
        v = Array.from(new Uint8Array(buf))
          .map((b) => b.toString(16).padStart(2, "0"))
          .join("");
        padded = "0".repeat(64 - v.length);
        encodedValue = encodedValue.concat(padded + v);
        break;
      case "bytes32":
        encodedValue = encodedValue.concat(value[i].toString().slice(2));
        break;
      default:
        throw new Error("Unsupported value type");
    }
  }

  return `0x${encodedValue}`;
}

function padNumber(num) {
  let v = BigInt(num).toString(16).padStart(32, "0");
  let padded = "0".repeat(64 - v.length);
  return padded + v;
}

const baseURL = `https://api.goshippo.com/tracks/`;
const trackingNumber = args[0];
const shippingCompany = args[1];
const orderId = args[2];
const store = args[3];

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

// encode status (uint8), orderNumber (bytes32), company (string)

const encoded = encodeValue(
  ["uint", "bytes32", "string"],
  [statusInt, orderId, shippingCompany]
);

return Functions.encodeString(encoded);
