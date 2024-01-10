import { keyPair1, parse_amount, find_one_by_type } from './helper'
import { SuiClient, getFullnodeUrl } from '@mysten/sui.js/client';
import data from './deployed_objects.json';
import { TransactionBlock } from '@mysten/sui.js/transactions';

const accountKey = process.env.ACCOUNT_KEY;

const toContractBase = function(obj:any) {
    return parseFloat(obj) * 1_000000000;
}

const packageId = data.packageId;
const fundBalances = data.fundProject.fundBalances;
const usdc_cointype = data.usdc.USDCcointype;

const toAppBase = function(obj:any) {
    return parseFloat(obj) / 1_000000000;
  };

async function getCoinWithAmount(txb:any, amount:string, client:any){
    const coins = await client.getCoins({
      owner: "0xc14f2502f48f29599cc94eb0f8c6037fee028fede1dc7dcccea56c6c6e9d20ce",
      coinType:usdc_cointype 
    })

    console.log(coins);

    const collectedCoins = [];
    const targetAmount = parseInt(amount);
    let collectedAmount = 0;

    let i = 0;
    while(i < coins.data.length && collectedAmount < targetAmount){
      const temp = coins.data[i];
      const tempAmount = toAppBase(parseInt(temp.balance));
      
      if(tempAmount >= targetAmount - collectedAmount){
        const [splittedCoin] = txb.splitCoins(txb.object(temp.coinObjectId),  [ txb.pure(toContractBase(targetAmount - collectedAmount))]);
        collectedCoins.push(splittedCoin);
        collectedAmount += (targetAmount - collectedAmount);
      }
      else{
        const [splittedCoin] = txb.splitCoins(txb.object(temp.coinObjectId), [txb.pure(toContractBase(tempAmount))]);
        collectedCoins.push(splittedCoin);
        collectedAmount += tempAmount;
      }
      i++;
    }
    try{
      if(collectedCoins.length > 1){
        txb.mergeCoins(collectedCoins[0], collectedCoins.slice(1));
      }
    }
    catch(e){
      console.log(e)
    }
    return collectedCoins[0];
  }


console.log('Starting tests.');

const DepositAnyToken = async (packageId: string, fund_balances_id: string) => {

const deposit_usdc_bag= new TransactionBlock
const keypair = keyPair1();
const client = new SuiClient({ url: getFullnodeUrl('testnet') });
const usdc_cointype = deposit_usdc_bag.object("0x3f26406ff0bb260bf08aab81502cac391a307bb006d11e88fa5b05bdaaa5d8f0")
const usdc_amount =  await getCoinWithAmount(deposit_usdc_bag, "1000000000", client);

console.log(usdc_amount)

deposit_usdc_bag.moveCall({
    target: `${packageId}::fund_project::deposit_to_bag`,
    arguments: [deposit_usdc_bag.object(fund_balances_id), usdc_amount , usdc_cointype],
    typeArguments: [data.usdc.USDCcointype]
})

console.log("User1 getting deposit usdc...") 

const read_result = await client.devInspectTransactionBlock({
    sender: keypair.toSuiAddress(),
    transactionBlock: deposit_usdc_bag
})

const return_values = read_result?.results?.[0].returnValues
if (!return_values) {
    console.log("Error: Return Values not found")
    process.exit(1)
}

console.log(return_values)
}

await DepositAnyToken(packageId, fundBalances );

