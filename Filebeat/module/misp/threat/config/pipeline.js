// Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
// or more contributor license agreements. Licensed under the Elastic License;
// you may not use this file except in compliance with the Elastic License.

var threat = (function () {
    var processor = require("processor");

    var decodeJson = new processor.DecodeJSONFields({
        fields: ["message"],
        target: "json",
    });

    var categorizeEvent = new processor.AddFields({
        target: "event",
        fields: {
            category: "threat-intel",
            type: "indicator",
        },
    });

    var setThreatFeedField = function (evt) {
        evt.Put("misp.threat_indicator.feed", "misp");
    };

    var convertFields = new processor.Convert({
        fields: [
            { from: "json.Event.info", to: "misp.threat_indicator.description" },
            { from: "json.Event.uuid", to: "misp.threat_indicator.id" },
        ],
        mode: "rename",
        ignore_missing: true,
    });

    var setAttackPattern = function (evt) {
        var indicator_type = evt.Get("json.type");
        var attackPattern;
        var arr;
        var ip;
        var filename;
        var v = evt.Get("json.value");
        evt.Put("message", v);
        evt.Put("misp.threat_indicator.type", indicator_type);
        switch (indicator_type) {
            case "AS":
                var asn;
                if (v.substring(0, 2) == "AS") {
                    asn = v.substring(2, v.length);
                } else {
                    asn = v;
                }
                attackPattern = '[' + 'as.number = ' + '\'' + asn + '\'' + ']';
                evt.Put("as.number", asn);
                break;
            case 'btc':
                attackPattern = '[' + 'bitcoin.address = ' + '\'' + v + '\'' + ']';
                break;
            case "domain":
                attackPattern = '[' + 'dns.question.name = ' + '\'' + v + '\'' + ' OR url.domain = ' + '\'' + v + '\'' + ']';
                evt.Put("dns.question.name", v);
                evt.Put("url.domain", v);
                break;
            case "domain|ip":
                arr = v.split("|");
                if (arr.length == 2) {
                    var domain = arr[0];
                    ip = arr[1].split("/")[0];
                    attackPattern = '[' + '(' + 'dns.question.name = ' + '\'' + domain + '\'' + ' OR url.domain = ' + '\'' + domain + '\'' + ')' +
                        ' AND ' + '(' + 'source.ip = ' + '\'' + ip + '\'' + ' OR destination.ip = ' + '\'' + ip + '\'' + ')' + ']';
                    evt.Put("dns.question.name", domain);
                    evt.Put("url.domain", domain);
                    evt.Put("source.ip", ip);
                    evt.Put("destination.ip", ip);
                }
                break;
            case 'email-src':
                attackPattern = '[' + 'user.email = ' + '\'' + v + '\'' + ']';
                evt.Put("user.email", v);
                break;
            case "filename":
                attackPattern = '[' + 'file.path = ' + '\'' + v + '\'' + ']';
                evt.Put("file.path", v);
                break;
            case "filename|md5":
                arr = v.split("|");
                if (arr.length == 2) {
                    filename = arr[0];
                    var md5 = arr[1];
                    attackPattern = '[' + 'file.hash.md5 = ' + '\'' + md5 + '\'' + ' AND file.path = ' + '\'' + filename + '\'' + ']';
                    evt.Put("file.hash.md5", md5);
                    evt.Put("file.path", filename);
                }
                break;
            case "filename|sha1":
                arr = v.split("|");
                if (arr.length == 2) {
                    filename = arr[0];
                    var sha1 = arr[1];
                    attackPattern = '[' + 'file.hash.sha1 = ' + '\'' + sha1 + '\'' + ' AND file.path = ' + '\'' + filename + '\'' + ']';
                    evt.Put("file.hash.sha1", sha1);
                    evt.Put("file.path", filename);
                }
                break;
            case "filename|sha256":
                arr = v.split("|");
                if (arr.length == 2) {
                    filename = arr[0];
                    var sha256 = arr[1];
                    attackPattern = '[' + 'file.hash.sha256 = ' + '\'' + sha256 + '\'' + ' AND file.path = ' + '\'' + filename + '\'' + ']';
                    evt.Put("file.hash.sha256", sha256);
                    evt.Put("file.path", filename);
                }
                break;
            case 'github-username':
                attackPattern = '[' + 'github.username = ' + '\'' + v + '\'' + ']';
                break;
            case "hostname":
                attackPattern = '[' + 'source.domain = ' + '\'' + v + '\'' + ' OR destination.domain = ' + '\'' + v + '\'' + ']';
                evt.Put("source.domain", v);
                evt.Put("destination.domain", v);
                break;
            case "ip-dst":
                ip = v.split("/")[0];
                attackPattern = '[destination.ip = ' + '\'' + ip + '\'' + ']';
                evt.Put("destination.ip", ip);
                break;
            case "ip-dst|port":
                arr = v.split("|");
                if (arr.length == 2) {
                  attackPattern = '[destination.ip = ' + '\'' + arr[0] + '\'' + ' AND destination.port = ' + '\'' + arr[1] + '\'' + ']';
                  evt.Put("destination.ip", arr[0]);
                }
                break;
            case "ip-src":
                ip = v.split("/")[0];
                attackPattern = '[' + 'source.ip = ' + '\'' + ip + '\'' + ']';
                evt.Put("source.ip", ip);
                break;
            case "link":
                attackPattern = '[' + 'url.full = ' + '\'' + v + '\'' + ']';
                evt.Put("url.full", v);
                break;
            case "md5":
                attackPattern = '[' + 'file.hash.md5 = ' + '\'' + v + '\'' + ']';
                evt.Put("file.hash.md5", v);
                break;
            case 'regkey':
                attackPattern = '[' + 'regkey = ' + '\'' + v + '\'' + ']';
                break;
            case "sha1":
                attackPattern = '[' + 'file.hash.sha1 = ' + '\'' + v + '\'' + ']';
                evt.Put("file.hash.sha1", v);
                break;
            case "sha256":
                attackPattern = '[' + 'file.hash.sha256 = ' + '\'' + v + '\'' + ']';
                evt.Put("file.hash.sha256", v);
                break;            
            case "sha512":
                attackPattern = '[' + 'file.hash.sha512 = ' + '\'' + v + '\'' + ']';
                evt.Put("file.hash.sha512", v);
                break;
            case "url":
                attackPattern = '[' + 'url.full = ' + '\'' + v + '\'' + ']';
                evt.Put("url.full", v);
                break;
            case 'yara':
                attackPattern = '[' + 'yara.rule = ' + '\'' + v + '\'' + ']';
                break; 
        }
        if (attackPattern == undefined) {
            evt.Put("error.message", 'Unsupported type: ' + indicator_type);
        }
        evt.Put("misp.threat_indicator.attack_pattern", attackPattern);
    };

    var pipeline = new processor.Chain()
        .Add(decodeJson)
        .Add(categorizeEvent)
        .Add(setThreatFeedField)
        .Add(convertFields)
        .Add(setAttackPattern)
        .Build();

    return {
        process: pipeline.Run,
    };
})();

function process(evt) {
    return threat.process(evt);
}
