module fund::fund_project { 

use std::string::{Self,String};
use sui::transfer;
use sui::object::{Self,UID,ID};
use sui::url::{Self,Url};
use sui::coin::{Self,Coin};
use sui::sui::SUI;
use sui::object_table::{Self,ObjectTable};
use sui::event;
use sui::tx_context::{Self,TxContext};
 use sui::vec_set::{Self, VecSet};
use sui::table::{Self, Table};
use sui::balance:: {Self, Balance};

// share object
struct Fund_Balances has key {
    id:UID,
    total_fund: Balance<SUI>,
    balances:Table<address,u64>, 
}

// only admin  
struct AdminCap has key {
    id:UID,
}

// share object
struct ShareHolders has key {
    id:UID,
    shareholders: VecSet<address>,
    //reel_allowance:u64,
    admin_allowance:u64,
    used_allowance:Table<address,u64>,
}

// event 
struct Receipt has key {
    id: UID,
    deposit_amount: u64,    
}

// event 
struct FundWithdraw has copy,drop {
    id:ID,
    amount:u64,
    recipient: address
}

// event 
struct FundDistributed has copy,drop {
    id:ID,
    recipients:vector<address>,
    amount:u64,
}

   // =================== Initializer ===================

fun init(ctx:&mut TxContext) {

transfer::share_object(
    Fund_Balances{
        id:object::new(ctx),
        total_fund:balance::zero(),
        balances:table::new(ctx),
    },
);

transfer::share_object(
    ShareHolders{
        id:object::new(ctx),
        shareholders:vec_set::empty(),
       // reel_allowance:0,
        admin_allowance:0,
        used_allowance:table::new(ctx)
    },
);

   // Admin capability object for the stable coin
 transfer::transfer(AdminCap { id: object::new(ctx) }, tx_context::sender(ctx) );

}

 // users can deposit fund to Fund_Balances share object. 

public entry fun deposit_fund(storage: &mut Fund_Balances,holders:&mut ShareHolders, amount:Coin<SUI>,ctx:&mut TxContext) {
    let caller_address = tx_context::sender(ctx);
    let deposit_amount = coin::value(&amount);
    
    // add SUI into the fund balance 
    let coin_balance: Balance<SUI> = coin::into_balance(amount);
    balance::join(&mut storage.total_fund, coin_balance);
    
     // increase sender donated amount in table
    increase_account_balance(storage,caller_address, deposit_amount);
    
    // create a Receipt for proof 
   let receipt: Receipt = Receipt {
        id:object:: new(ctx),
        deposit_amount,
      };

    transfer::transfer(receipt, tx_context::sender(ctx));
   
}

// public entry fun user_withdraw(storage: &mut Fund_Balances,holders: &mut ShareHolders,amount:Coin<SUI>,ctx:&mut TxContext) {
//      let caller_address = tx_context::sender(ctx);
//      assert!(vec_set::contains(&holders.shareholders, &caller_address) == true, 0);
     
//      let allowance = *table::borrow(&holders.used_allowance, caller_address);
//      assert!(allowance < holders.admin_allowance,0);

//      let total_fund = &storage.total_fund;
//      let target_amount = ((total_fund) / (get_shareholders_length(holders))) * (allowance / 100);
//      let withdraw_amount = coin::value(&amount);
     
//     / let raised: Coin<SUI> = coin::take(&mut storage.total_fund, withdraw_amount, ctx);

//       transfer::public_transfer(raised, tx_context::sender(ctx));
     
// }

fun fund_distribution(_:&AdminCap) {

}
 // admin give allowance for shareholders get withdraw funds. 
fun give_allowance_withdraw(_:&AdminCap,receipt:&mut ShareHolders,allowance:u64) {
    let new_admin_allowance = allowance + receipt.admin_allowance;
    assert!(new_admin_allowance<=100,0);
    receipt.admin_allowance = new_admin_allowance;
}
 
 //admin add shareholder for contract
entry public fun add_shareholders (_:&AdminCap,receipt:&mut ShareHolders,shareholder:address) {
    vec_set::insert(&mut receipt.shareholders,shareholder);
   
}
 
 // admin removes shareholder from contract
entry public fun remove_shareholders (_:&AdminCap,receipt:&mut ShareHolders,shareholder:address) {
    assert!(get_shareholders_length(receipt) >=3,0);
    vec_set::remove(&mut receipt.shareholders,&shareholder);   
}

 // get receipt.shareholders.length 
 fun get_shareholders_length(receipt:&ShareHolders): u64 {
     vec_set::size(&receipt.shareholders)
}
  // update users deposit_amount in Table 
  fun increase_account_balance(storage: &mut Fund_Balances, recipient: address, amount:u64) {
        
        if(table::contains(&storage.balances, recipient)) {
            let existing_balance = table::remove(&mut storage.balances, recipient);
            table::add(&mut storage.balances, recipient, existing_balance +amount);
        } else {
            table::add(&mut storage.balances, recipient, amount); 
        };
    }






}