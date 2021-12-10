#!/usr/bin/node

const l = console.log;
const fs = require("fs");
const cheerio = require("cheerio");

if (process.argv.length < 3) {
    process.exit();
}

const file = fs.readFileSync(global.process.argv[2], "utf8");

const $ = cheerio.load(file);
const body = $("body");
const images = body.find("img.slide_image");

images.each(function (idx, item) {
// 	l(item.attribs);
// 	l(item.attribs.src);
	l(item.attribs["data-full"]);
});


