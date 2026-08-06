#!/usr/bin/env node
import { bridgeHealth } from "../src/health.mjs";

const projectRoot = process.argv[2] || process.cwd();
const health = await bridgeHealth({ projectRoot });
console.log(JSON.stringify(health, null, 2));
process.exit(health.ok ? 0 : 2);
