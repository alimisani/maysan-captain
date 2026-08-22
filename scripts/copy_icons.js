const fs = require('fs');
const path = require('path');

const src = path.join(__dirname, '../assets/icon/app.png');

const targets = [
  'web/favicon.png',
  'web/icons/Icon-192.png',
  'web/icons/Icon-512.png',
  'web/icons/Icon-maskable-192.png',
  'web/icons/Icon-maskable-512.png',
  'android/app/src/main/res/mipmap-mdpi/ic_launcher.png',
  'android/app/src/main/res/mipmap-hdpi/ic_launcher.png',
  'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png',
  'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png',
  'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png',
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png',
];

for (const target of targets) {
  const fullPath = path.join(__dirname, '..', target);
  const dir = path.dirname(fullPath);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
  fs.copyFileSync(src, fullPath);
  console.log(`Copied icon to ${target}`);
}
