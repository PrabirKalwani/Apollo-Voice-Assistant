const express = require("express");
const router = require("./routes");
const cookieParser = require("cookie-parser");
const cors = require("cors");
require("dotenv").config();

const PORT = 6969;

const app = express();

app.use(
  cors({
    origin: true,
    allowedHeaders: "X-Requested-With, Content-Type, auth-token",
  })
);
app.use(express.json());
app.use(cookieParser());
app.use(router);

app.get("/", (req, res) => {
  res.send("Backend Ready");
});

app.listen(PORT, () => {
  console.log(`Listening on port ${PORT}`);
});
