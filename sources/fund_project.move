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
use std::vector;
use std::debug;

const ERROR_INVALID_ARRAY_LENGTH: u64 = 0;
const ERROR_INVALID_PERCENTAGE_SUM: u64 = 1;
const ERROR_INVALID_VALUE:u64 = 2;

// share object
struct Fund_Balances has key {
    id:UID,
    total_fund: Balance<SUI>,
}

// only admin  
struct AdminCap has key {
    id:UID,
}

// share object
struct ShareHolders has key {
    id:UID,
    shareholders: Table<address,u64>,
    used_allowance:Table<address,u64>,
    old_shareholders:vector<address>,
}
// object for add shareholer
struct ShareHoldersNew has drop {
    shareholder: address,
    share_percentage: u64,
}

   // =================== Initializer ===================

fun init(ctx:&mut TxContext) {

transfer::share_object(
    Fund_Balances{
        id:object::new(ctx),
        total_fund:balance::zero(),
    },
);

transfer::share_object(
    ShareHolders{
        id:object::new(ctx),
        shareholders:table::new(ctx),
        used_allowance:table::new(ctx),
        old_shareholders:vector::empty(),
    },
);

   // Admin capability object for the stable coin
 transfer::transfer(AdminCap { id: object::new(ctx) }, tx_context::sender(ctx) );

}
 // users can deposit fund to Fund_Balances share object. 

public entry fun deposit_fund(storage: &mut Fund_Balances, amount:Coin<SUI>, ctx:&mut TxContext) {
    let coin_balance: Balance<SUI> = coin::into_balance(amount);
    balance::join(&mut storage.total_fund, coin_balance);
    
}

// public entry fun user_withdraw(storage: &mut Fund_Balances,holders: &mut ShareHolders,amount:Coin<SUI>,ctx:&mut TxContext) {
//      let caller_address = tx_context::sender(ctx);
//      assert!(vec_set::contains(&holders.shareholders, &caller_address) == true, 0);

//      let allowance = *table::borrow(&holders.used_allowance, caller_address);
//      assert!(allowance < holders.admin_allowance,0);

//      let total_fund = &storage.total_fund;
//      let target_amount = ((total_fund) / (get_shareholders_length(holders))) * (allowance / 100);
//      let withdraw_amount = coin::value(&amount);

//      let raised: Coin<SUI> = coin::take(&mut storage.total_fund, withdraw_amount, ctx);

//       transfer::public_transfer(raised, tx_context::sender(ctx));

// }

public fun admin_withdraw(_:&AdminCap, fund: &mut Fund_Balances,withdraw_amount:u64, ctx:&mut TxContext) { 
    // check the input amount <= fund_balances
    let withdraw: Coin<SUI> = coin::take(&mut fund.total_fund, withdraw_amount, ctx);
    transfer::public_transfer(withdraw, tx_context::sender(ctx));
}

fun fund_distribution(_:&AdminCap) {

}

 // admin give allowance for shareholders get withdraw funds. 
// fun give_allowance_withdraw(_:&AdminCap,receipt:&mut ShareHolders,allowance:u64) {
//     let new_admin_allowance = allowance + receipt.admin_allowance;
//     assert!(new_admin_allowance<=100,0);
//     receipt.admin_allowance = new_admin_allowance;
// }

 ///// admin add or remove shareholders from contract
public fun set_shareholders(_: &AdminCap, receipt:&mut ShareHolders, shareholder:vector<ShareHoldersNew>) {
    // check input length >= 2 
   assert!(vector::length(&shareholder) >= 2, ERROR_INVALID_ARRAY_LENGTH);
    // check percentange sum must be equal to 100 
    let percentange_sum:u64 = 0;
    //let old_shareholders: u64 = vector::length(&receipt.old_shareholders);
    
    while(!vector::is_empty(&receipt.old_shareholders)) {
        let shareholder_address = vector::pop_back(&mut receipt.old_shareholders);
        table::remove(&mut receipt.shareholders, shareholder_address);
    };

     // add shareholders to table. 

    while(!vector::is_empty(&shareholder)) {
        let share_holder = vector::pop_back(&mut shareholder); 
        // add new shareholders to old_shareholders vector. 
        vector::push_back(&mut receipt.old_shareholders, share_holder.shareholder);   
        // add table to new shareholders and theirs percentange
        table::add(&mut receipt.shareholders, share_holder.shareholder , share_holder.share_percentage);
        // sum percentage
        percentange_sum= percentange_sum + share_holder.share_percentage;   
    };
        // check percentage is equal to 100.
        assert!(percentange_sum == 100, ERROR_INVALID_PERCENTAGE_SUM);
}

 // get receipt.shareholders.length 
fun get_shareholders_length(receipt:&ShareHolders): u64 {
     table::length(&receipt.shareholders)
}

  // update users deposit_amount in Table 
// fun increase_account_balance(storage: &mut Fund_Balances, recipient: address, amount:u64) {

//       if(table::contains(&storage.balances, recipient)) {
//           let existing_balance = table::remove(&mut storage.balances, recipient);
//           table::add(&mut storage.balances, recipient, existing_balance +amount);
//       } else {
//           table::add(&mut storage.balances, recipient, amount); 
//       };
//   }

#[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx); 
}
     // create a shareholder
    public fun create_shareholdernew(shareholder: address, share_percentage: u64): ShareHoldersNew {
        ShareHoldersNew { shareholder, share_percentage}
    }
    // return shareholder percentange u64.
    public fun return_shareholder_percentage(sh:&ShareHolders,recipient:address): u64  {
           let share_percentage_ref= table::borrow(&sh.shareholders,recipient);
           *share_percentage_ref
    }
    // return total_fund value as a u64
    public fun return_total_fund(fund: &Fund_Balances): u64 {
        balance::value(&fund.total_fund)
        //debug::print(&x);
}

}