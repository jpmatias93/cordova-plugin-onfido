#!/usr/bin/env node

const fs = require('fs')

const path = require('path');



module.exports = function(context) {

    const platformRoot = path.join(context.opts.projectRoot, 'platforms/android/app/src/main');



    addPropertyManifest(platformRoot,

        "android:supportsRtl",

        false);

};



function addPropertyManifest(platformRoot, property, value) {

    let manifestFile = path.join(platformRoot, 'AndroidManifest.xml');

    if (fs.existsSync(manifestFile)) {

        let data = fs.readFileSync(manifestFile, {encoding:'utf8', flag:'r'});

        if (data.indexOf(property) == -1) {

            data = data.replace(/<application/g, `<application ${property}="${value}"`);

        }

        fs.writeFileSync(manifestFile, data);

    }

}
