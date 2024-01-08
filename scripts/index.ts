import { SuiClient, getFullnodeUrl } from '@mysten/sui.js/client';
import { TransactionBlock } from '@mysten/sui.js/transactions';
import { Ed25519Keypair } from '@mysten/sui.js/keypairs/ed25519';
import { fromB64 } from "@mysten/sui.js/utils";

import path, { dirname } from "path";
import { fileURLToPath } from "url";
import { execSync } from "child_process";
import { writeFileSync } from "fs";
import { SuiObjectChange } from "@mysten/sui.js/client";

const privkey = process.env.PRIVATE_KEY
if (!privkey) {
    console.log("Error: DEPLOYER_B64_PRIVKEY not set as env variable.")
    process.exit(1)
}

const path_to_scripts = dirname(fileURLToPath(import.meta.url))

const keypair = Ed25519Keypair.fromSecretKey(fromB64(privkey).slice(1))
const client = new SuiClient({ url: getFullnodeUrl('devnet') });

const path_to_contracts = path.join(path_to_scripts, "../sources")

console.log("Building move code...")

const { modules, dependencies } = JSON.parse(execSync(
    `sui move build --dump-bytecode-as-base64 --path ${path_to_contracts}`,
    { encoding: "utf-8" }
))

console.log("Deploying contracts...");
console.log(`Deploying from ${keypair.toSuiAddress()}`)

const deploy_trx = new TransactionBlock()
const [upgrade_cap] = deploy_trx.publish({
    modules, dependencies
})

deploy_trx.transferObjects([upgrade_cap], deploy_trx.pure(keypair.toSuiAddress()))

const { objectChanges, balanceChanges } = await client.signAndExecuteTransactionBlock({
    signer: keypair, transactionBlock: deploy_trx, options: {
        showBalanceChanges: true,
        showEffects: true,
        showEvents: true,
        showInput: false,
        showObjectChanges: true,
        showRawInput: false
    }
})

if (!balanceChanges) {
    console.log("Error: Balance Changes was undefined")
    process.exit(1)
}

if (!objectChanges) {
    console.log("Error: object  Changes was undefined")
    process.exit(1)
}
console.log(objectChanges)

function parse_amount(amount: string): number {
    return parseInt(amount) / 1_000_000_000
}

console.log(`Spent ${Math.abs(parse_amount(balanceChanges[0].amount))} on deploy`)

const published_change = objectChanges.find(change => change.type == "published")
if (published_change?.type !== "published") {
    console.log("Error: Did not find correct published change")
    process.exit(1)
}

const find_one_by_type = (changes: SuiObjectChange[], type: string) => {
    const object_change = changes.find(change => change.type == "created" && change.objectType == type)
    if (object_change?.type == "created") {
        return object_change.objectId
    }
}

const deployed_address: any = {
    PACKAGE_ID: published_change.packageId
}

// Get Fund_Balances Share object 
const fund_balances = `${deployed_address.PACKAGE_ID}::fund_project::Fund_Balances`

const fund_balances_id = find_one_by_type(objectChanges, fund_balances)
if (!fund_balances_id) {
    console.log("Error: Could not find Place object")
    process.exit(1)
}

deployed_address.Fund_Balances = fund_balances_id

const deployed_path1 = path.join(path_to_scripts, "../scripts/deployed_objects.json")
writeFileSync(deployed_path1, JSON.stringify(deployed_address, null, 4))

// Get ShareHolder shareobject
const share_balances = `${deployed_address.PACKAGE_ID}::fund_project::ShareHolders`

const share_holders_id = find_one_by_type(objectChanges, share_balances)
if (!share_holders_id) {
    console.log("Error: Could not find Place object")
    process.exit(1)
}

deployed_address.Shareholders = share_holders_id

const deployed_path2 = path.join(path_to_scripts, "../scripts/deployed_objects.json")
writeFileSync(deployed_path2, JSON.stringify(deployed_address, null, 4))





