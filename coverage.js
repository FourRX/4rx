#!/usr/bin/env node

const { execSync } = require('child_process');
const { runCoverage } = require('@openzeppelin/test-environment');

async function main () {
  await runCoverage(
    ['ERC20/FRX.sol', 'Farm/MasterChef.sol'],
    'npx oz compile',
    './node_modules/.bin/mocha --exit --timeout 10000 --recursive --exclude **/*-hh.test.js'.split(' '),
  );

  if (process.env.CI) {
    execSync('curl -s https://codecov.io/bash | bash -s -- -C "$CIRCLE_SHA1"', { stdio: 'inherit' });
  }
}

main().catch(e => {
  console.error(e);
  process.exit(1);
})
