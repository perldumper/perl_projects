#!/usr/bin/node

// works only for user made list

const l = console.log;
const fs = require("fs");
const file = fs.readFileSync(global.process.argv[2], "utf8");
const cheerio = require("cheerio");
const $ = cheerio.load(file);

const get_year = new RegExp("^.*?(\\d+(?:–\\d+)?).*");

// $(".lister-item.mode-detail").each(function (idx, elem) {
//     const list_index = elem.children[3].children[1].children[1].children[0].data;
//     const      title = elem.children[3].children[1].children[3].children[0].data;
//     var         year = elem.children[3].children[1].children[5].children[0].data;
// 
//     year = year.replace(get_year, "$1");
//     l(`${list_index}`.padEnd(5, " ") + `(${year}) ${title}`);
// });


$(".lister-item.mode-detail > .lister-item-content > .lister-item-header").each(function (idx, elem) {
    
    var [list_index, title, year] =
    elem.children
    .filter(function (elem, idx) {
        if (elem.type != 'text') {
            return elem;
        }
    })
    .map(function (elem, idx){
        return elem.children[0].data;
    });

    year = year.replace(get_year, "$1");
    l(`${list_index}`.padEnd(5, " ") + `(${year}) ${title}`);

});




