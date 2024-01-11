import { SuiClient, getFullnodeUrl } from '@mysten/sui.js/client';
import { TransactionBlock } from '@mysten/sui.js/transactions';
import { keyPair1, parse_amount, find_one_by_type} from './helper'
import data from './deployed_objects.json';


const packageId = data.packageId;
const fundBalances = data.fundProject.fundBalances;
const shareholders = data.fundProject.shareholders;
const usdc_cointype = data.usdc.USDCcointype;
const admincap = data.fundProject.AdminCap

export const DepositSuiBag = async (packageId: string, fund_balances_id: string) => {

    const keypair = keyPair1();
    const client = new SuiClient({ url: getFullnodeUrl('testnet') });

    const deposit_sui_bag = new TransactionBlock

    const [coin] = deposit_sui_bag.splitCoins(deposit_sui_bag.gas, [100]);


    deposit_sui_bag.moveCall({
        target: `${packageId}::fund_project::deposit_to_bag_sui`,
        arguments: [deposit_sui_bag.object(fund_balances_id), coin]
    })

    console.log("User1 getting deposit sui...")

    const read_result = await client.devInspectTransactionBlock({
        sender: keypair.toSuiAddress(),
        transactionBlock: deposit_sui_bag
    })

    const return_values = read_result?.results?.[0].returnValues
    if (!return_values) {
        console.log("Error: Return Values not found")
        process.exit(1)
    }

    console.log(return_values)

}

export const SetShareHolders = async () => {

    const keypair = keyPair1();
    const client = new SuiClient({ url: getFullnodeUrl('testnet') });
    const setshareholders = new TransactionBlock

    const user1:any = {
        shareholder:  "0x5fb75c1761c43acfd30b99443d4307101f57391cb1a4b7eb5d795fd91a8aa87a",
        share_percentage: 40 
    }

    const user2:any = {
        shareholder:  "0xd59033a3f71a842f14b736a84256ffaf42deff102239101236c2b6ca8ff7336d",
        share_percentage: 30 
    }

    const user3:any = {
        shareholder:  "0xb1f0fc1cf4a4898a77a5b1b3f9216a4dee2f317b1498820ac0ed362c6d9308c8",
        share_percentage: 30
    }

    const shareholdersVec = setshareholders.makeMoveVec({ objects: [setshareholders.object(user1), setshareholders.object(user2), setshareholders.object(user3)]});
    console.log("admin set shareholders...")

    setshareholders.moveCall({
        target: `${packageId}::fund_project::set_shareholders`,
        arguments: [setshareholders.object(admincap), setshareholders.object(shareholders), shareholdersVec]
    });


    const read_result = await client.devInspectTransactionBlock({
        sender: keypair.toSuiAddress(),
        transactionBlock: setshareholders
    })

    const return_values = read_result?.results?.[0].returnValues
    if (!return_values) {
        console.log("Error: Return Values not found")
        process.exit(1)
    }

    console.log(return_values)
}



 //DepositSuiBag(packageId, fundBalances)

 await SetShareHolders();






