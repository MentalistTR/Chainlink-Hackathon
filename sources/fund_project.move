module fund::fund_project { 

// use fund::token1::{USDC};
// use fund::token2;
use std::string::{Self,String};
use sui::transfer;
use sui::object::{Self,UID,ID};
use sui::url::{Self,Url};
use sui::coin::{Self, Coin, CoinMetadata};
use sui::sui::SUI;
use sui::object_table::{Self,ObjectTable};
use sui::event;
use sui::tx_context::{Self,TxContext};
use sui::vec_set::{Self, VecSet};
use sui::table::{Self, Table};
use sui::balance:: {Self, Balance};
use sui::bag::{Self,Bag};
use std::vector;
use std::debug;


const ERROR_INVALID_ARRAY_LENGTH: u64 = 0;
const ERROR_INVALID_PERCENTAGE_SUM: u64 = 1;
const ERROR_INVALID_VALUE:u64 = 2;
const ERROR_YOU_ARE_NOT_SHAREHOLDER:u64 =3;
const ERROR_INSUFFICIENT_FUNDS:u64 =4;
const ERROR_SHARE_ALREADY_CREATED:u64 = 5;

// share object
struct Fund_Balances has key, store {
    id:UID,
    total_fund: Bag,
    coin_names: vector<String>,
}

// only admin  
struct AdminCap has key {
    id:UID,
    shareholders_created:bool,
}

// share object
struct ShareHolders has key {
    id:UID,
    shareholders_percentage: Table<address, u64>, // shareholders allowance percentage of the  distrubution amount 
    shareholders_amount: Table<address, Bag>,    // shareholders total withdraw amount 
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
            total_fund:bag::new(ctx),
            coin_names:vector::empty<String>(),
         },
     );
     
    transfer::share_object(
        ShareHolders {
            id:object::new(ctx),
            shareholders_percentage:table::new(ctx),
            shareholders_amount:table::new(ctx),
            old_shareholders:vector::empty(),
        },
    );
   // Admin capability object for the stable coin
   transfer::transfer(AdminCap 
 { id: object::new(ctx), shareholders_created:false}, tx_context::sender(ctx) );

}

 // users can deposit fund to Fund_Balances share object. 
public fun deposit_to_bag<T>(bag: &mut Fund_Balances, coin:Coin<T>, coin_metadata: &CoinMetadata<T>) {
    let balance = coin::into_balance(coin);
    let name = coin::get_name(coin_metadata);
    // lets check is there any same token in our bag
   if(bag::contains(&bag.total_fund, name) == true) { 
    
        let coin_value = bag::borrow_mut(&mut bag.total_fund, name);

        balance::join(coin_value, balance);
    }
        // if it is not lets add it.
    else { 
         vector::push_back(&mut bag.coin_names, name);
         bag::add(&mut bag.total_fund, name, balance);
    }
}

public fun deposit_to_bag_sui(bag: &mut Fund_Balances, coin:Coin<SUI>) {
    // lets define balance and name 
    let balance = coin::into_balance(coin);
    let name  = b"sui";
    let name_string = string::utf8(name);
        // lets check is there any sui token in bag
        if(bag::contains(&bag.total_fund, name_string) == true) { 
            let coin_value = bag::borrow_mut(&mut bag.total_fund, name_string);

             balance::join(coin_value, balance);
    }
         else { 
             vector::push_back(&mut bag.coin_names, name_string);
             bag::add(&mut bag.total_fund, name_string, balance);
    }
    
}

public fun shareholder_withdraw<T>(shareholders: &mut ShareHolders, amount:u64, coin_name:String,  ctx:&mut TxContext) {
    let sender = tx_context::sender(ctx);
    // firstly, check >  Is sender shareholder? 
      assert!(
       table::contains(&shareholders.shareholders_amount, sender),
        ERROR_YOU_ARE_NOT_SHAREHOLDER   
     );
      // let take shareholder_bag from table 
      let share_holder_bag = table::borrow_mut(&mut shareholders.shareholders_amount, sender);
      //decrease balance in table 
      let coin_value = bag::borrow_mut<String, Balance<T>>( share_holder_bag, coin_name);
      // calculate withdraw balance 
      let coin_transfer = coin::take(coin_value, amount, ctx);
      // send fund to sender 
      transfer::public_transfer(coin_transfer, sender);       
}

public fun admin_withdraw<T>(_:&AdminCap, fund:&mut Fund_Balances, withdraw_amount:u64, coin_name:String, ctx:&mut TxContext) { 
    // check the input amount <= fund.total_fund - fund.locked_amount
    let total_value = bag::borrow_mut<String, Balance<T>>( &mut fund.total_fund, coin_name); 
    let withdraw = coin::take(total_value, withdraw_amount, ctx);
    transfer::public_transfer(withdraw, tx_context::sender(ctx));
}

   // calculate shareholder_withdraw_amount and add table it
public fun fund_distribution<T>(_:&AdminCap, fund:&mut Fund_Balances, shareholder:&mut ShareHolders, distribution_amount: u64, coin_name: String, ctx:&mut TxContext) {
    let shareholder_vector_len: u64 = vector::length(&shareholder.old_shareholders);
    let j: u64 = 0;
    let i : u64 = 0;

         while (j < shareholder_vector_len) {
            // take address from oldshareholder vector
            let share_holder_address = vector::borrow(&shareholder.old_shareholders, j);
            
                if (!table::contains(&shareholder.shareholders_amount, *share_holder_address)) {
                    let bag = bag::new(ctx);
                    table::add(&mut shareholder.shareholders_amount,*share_holder_address,bag);
             }; 
             // take share_holder percentage from table
             let share_holder_percentage = table::borrow(&shareholder.shareholders_percentage, *share_holder_address);
             // calculate shareholder withdraw tokens
             let share_holder_withdraw_amount =  (distribution_amount * *share_holder_percentage ) / 10000 ;
             // Calculate the total fund of that coin type in the bag
             let shareholder_bag = table::borrow_mut<address, Bag>(&mut shareholder.shareholders_amount, *share_holder_address);
             // let define shareholder Bag
             let total_coin_value = bag::borrow_mut<String, Balance<T>>(&mut fund.total_fund, coin_name);
             // calculate the distribute coin value to shareholder 
            
             let withdraw_coin = balance::split<T>( total_coin_value, share_holder_withdraw_amount);
            // add to share_holder amount
                 if(bag::contains(shareholder_bag, coin_name) == true) { 
                    let coin_value = bag::borrow_mut( shareholder_bag, coin_name);
                    balance::join(coin_value, withdraw_coin);
                }
                 else { 
                    bag::add(shareholder_bag, coin_name, withdraw_coin);
                 };
                     j = j + 1;       
                };                     
    }


    // admin add or remove shareholders from contract
public fun set_shareholders(_: &AdminCap, receipt:&mut ShareHolders, shareholder:vector<ShareHoldersNew>) {
    // check input length >= 2 
   assert!(vector::length(&shareholder) >= 2, ERROR_INVALID_ARRAY_LENGTH);
    // check percentange sum must be equal to 100 
    let percentange_sum:u64 = 0;

    while(!vector::is_empty(&receipt.old_shareholders)) {
        let shareholder_address = vector::pop_back(&mut receipt.old_shareholders);
        table::remove(&mut receipt.shareholders_percentage, shareholder_address);
    };
     // add shareholders to table. 
    while(!vector::is_empty(&shareholder)) {
        let share_holder = vector::pop_back(&mut shareholder); 
        // add new shareholders to old_shareholders vector. 
        vector::push_back(&mut receipt.old_shareholders, share_holder.shareholder);   
        // add table to new shareholders and theirs percentange
        table::add(&mut receipt.shareholders_percentage, share_holder.shareholder , share_holder.share_percentage);
         // sum percentage
        percentange_sum= percentange_sum + share_holder.share_percentage;

    };
        // check percentage is equal to 100.
        assert!(percentange_sum == 10000, ERROR_INVALID_PERCENTAGE_SUM);
}

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
           let share_percentage_ref= table::borrow(&sh.shareholders_percentage, recipient);
           *share_percentage_ref / 100
    }
    
    public fun get_bag_fund<T>(bag:& Fund_Balances, coin_metada: &CoinMetadata<T>): &Balance<T> {
        bag::borrow(&bag.total_fund, coin::get_name(coin_metada))
    }

      public fun get_bag_fund_SUI(bag: &Fund_Balances): &Balance<SUI> {
         let name  = b"sui";
         let name_string = string::utf8(name);
            bag::borrow(&bag.total_fund, name_string)
    }
   //return shareholder allowance withdraw amount 

     public fun return_shareholder_allowance_amount<T>(shareholder:&ShareHolders, token_name:String, holder:address): u64  {
           let shareholder_bag = table::borrow<address, Bag>(&shareholder.shareholders_amount, holder);
           let shareholder_allowance = bag::borrow<String, Balance<T>>(shareholder_bag, token_name );
           balance::value<T>(shareholder_allowance)
    }

}