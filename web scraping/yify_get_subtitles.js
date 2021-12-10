#!/usr/bin/node

// request json rather than webpage ??

const l = console.log;
const JSON = require("JSON");
const request = require('request');
const readline = require("readline-sync");
const cheerio = require("cheerio");
const fs = require("fs");

// TERMINAL COLORS
const [reset, green, yellow] = ["\x1b[0m", "\x1b[32m", "\x1b[33m"];

// CONFIGURATIONS
// const yify_website = "https://yts-subs.com/";
const yify_website = "https://yts-subs.com";
const language = "English";
const useragent = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.114 Safari/537.36";

// var url;
let url;

if (global.process.argv.length <= 2) {
    const choice_ = readline.question(green + "\nMovie title : " + reset);
//     l(choice_);
    url = encodeURI(yify_website + "/search/ajax?mov=" + choice_);
}
else {
    url = encodeURI(yify_website + "/search/ajax?mov="
                     + global.process.argv.slice(2).join(" "));
}
// l(url);
// process.exit();

function arraysSameLength(...arrays) {
    var len = arrays[0].length;
    for(i=1; i < arrays.length; i++) {
        if (len != arrays[i].length) {
            return false;
        }
    }
    return true;
}

function zip(array_a, array_b) {
    return array_a.map( (_,i) => {
        if (typeof array_a[i] == "object") {    // array_a[i] is an array
            return array_a[i].concat(array_b[i])
        }
        else {
            return [array_a[i], array_b[i]]     // array_a[i] is a "scalar"
        }
    })
}

function transpose(...arrays) {
    if(! arraysSameLength(...arrays)) {
        return undefined;
    }
    return arrays.reduce(zip)
}

request(url, {headers: { 'User-Agent': useragent }}, (err, res, body) => {
    if (err) { return l(`error ${err} while fetching search results page`); }
    const movies = JSON.parse(body)
                   .map( (elem) => {
                       const year        = elem.mv_mainTitle.match(/\((\d+)\)/)[1];
                       elem.mv_mainTitle = elem.mv_mainTitle.replace(/\s+\(\d+\)\s*$/, "");
//                        return Object.assign(elem, { "year": year }) }
                       return Object.assign(elem, { year: year }) }
                   )
                   .sort( (a,b) => a.year < b.year);

    movies.forEach( (elem, idx) => {
        l(yellow + ` ${idx}`.padEnd(5, " ") + reset
            + `(${elem.year})` + `  ${elem.mv_mainTitle}`);
    });

    const choice = readline.question(green + "\nWhich movie ? " + reset);
//     const movie_page = "https://yts-subs.com/movie-imdb/" + movies[choice].mv_imdbCode;
    const movie_page = yify_website + "/movie-imdb/" + movies[choice].mv_imdbCode;


    request(movie_page, {headers: { 'User-Agent': useragent }}, (err, res, body) => {
        if (err) { return l(`error ${err}\nwhile fetching movie page`); }

        const $ = cheerio.load(body);

        const sub_lang = $("table.table.other-subs > tbody > tr span.sub-lang")
                          .map((_, e) => e.children[0].data ).toArray();

        const links = $("table.table.other-subs > tbody > tr a.subtitle-download")
                          .map((_, e) => e.attribs.href ).toArray();

//         const description = $("table.table.other-subs > tbody > tr span.text-muted")
//                             .map((_, e) => e.next.data ).toArray();

        var descriptions = [];

        $("table.table.other-subs > tbody > tr span.text-muted")
        .each( (_, e) =>  descriptions.push(
            e.parent.children
            .filter( (e, _) => e.type == 'text' && ! e.data.match(/^\s+$/) )
            .map( (e) => e.data ).join("").trim()
        ));

//         const movies = transpose(sub_lang, links, description);
        const movies = transpose(sub_lang, links, descriptions);
        const chosen_language = movies.filter( (e) => e[0] == language );

        chosen_language.forEach((e, i) => {
            l(yellow + ` ${i}`.padEnd(5, " ") + reset + e[2] );
        });

        const choice = readline.question(green + "\nWhich subtitle ? " + reset);

        const subtitle_page = yify_website + chosen_language[choice][1];
        l(subtitle_page);
//         process.exit();

        request(subtitle_page, {headers: { 'User-Agent': useragent }},
            (err, res, body) => {
            if (err) { return l(`error ${err}\nwhile fetching subtitle page`); }

            const $ = cheerio.load(body);

            const subtitle_link = $(".download-subtitle")[0].attribs.href;

	        request(subtitle_link, {headers: { 'User-Agent': useragent }, encoding: null }, (err, res, body) => {
        		if (err) { return l(`error ${err} while fetching subtitle file`); }
                const filename_re = new RegExp("[^/]+$");
        		const filename = subtitle_link.match(filename_re)[0];
        		l(filename);
        		fs.writeFileSync(filename, body, "binary");
        	});
        });
    });
});







