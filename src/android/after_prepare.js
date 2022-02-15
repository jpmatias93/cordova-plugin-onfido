#!/usr/bin/env node

const fs = require('fs')

const path = require('path');



module.exports = function(context) {

    const platformRoot = path.join(context.opts.projectRoot, 'platforms/android/app/src/main');



    addPropertyManifest(platformRoot,

        "android:supportsRtl",

        true);

};



function addPropertyManifest(platformRoot, property, value) {

    let manifestFile = path.join(platformRoot, 'AndroidManifest.xml');

    if (fs.existsSync(manifestFile)) {

        let data = fs.readFileSync(manifestFile, {encoding:'utf8', flag:'r'});

        const versionRegex = /(<application [\S\s]*?android:supportsRtl=")[^"]+("[\S\s]*?>)/g;

        const replaced = data.replace( versionRegex, `$1${ value }$2` );

        fs.writeFileSync(manifestFile, replaced);

    }

}
