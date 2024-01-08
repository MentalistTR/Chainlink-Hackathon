import { SuiClient, getFullnodeUrl } from '@mysten/sui.js/client';
import { TransactionBlock } from '@mysten/sui.js/transactions';
import { keyPair1, parse_amount, find_one_by_type } from './helper'
import data from './deployed_objects.json';

const packageId = data.PACKAGE_ID;
const fundBalances = data.Fund_Balances;
const shareholders = data.Shareholders;

export const depositSuiBag = async (packageId: string, fund_balances_id: string) => {

    const keypair = keyPair1();
    const client = new SuiClient({ url: getFullnodeUrl('devnet') });

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


