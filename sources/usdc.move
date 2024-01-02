module fund::usdc {
    
    use std::option;
    use sui::coin;
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    struct USDC has drop {}

    fun init(witness: USDC, ctx: &mut TxContext) {
        let (treasury, metadata) = coin::create_currency(witness, 6, b"USDC", b"usdc", b"", option::none(), ctx);
        transfer::public_freeze_object(metadata);
        transfer::public_transfer(treasury, tx_context::sender(ctx))
    }
    
    #[test_only]
         public fun init_for_testing_usdc(ctx: &mut TxContext) {
            init(USDC {}, ctx); 
}  

}