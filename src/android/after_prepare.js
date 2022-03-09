#!/usr/bin/env node

const fs = require('fs')

const path = require('path');



module.exports = function(context) {

    const platformRoot = path.join(context.opts.projectRoot, 'platforms/android/app/src/main');



    addPropertyManifest(platformRoot,

        "android:supportsRtl",

        false);

    changeColorProperty(platformRoot,

        "android:supportsRtl",

        false);

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

function changeColorProperty(platformRoot, property, value) {

    let colorsFile = path.join(platformRoot, 'colors.xml');

    if (fs.existsSync(colorsFile)) {

        let data = fs.readFileSync(colorsFile, {encoding:'utf8', flag:'r'});

        const versionRegex = /<color name="onfidoPrimaryButtonColor">[\s\S]*?<\/color>/g;

        const replaced = data.replace( versionRegex, `<color name="onfidoPrimaryButtonColor">#f05d1a</color>` );

        fs.writeFileSync(colorsFile, replaced);

    }

}
