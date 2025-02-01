import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Can register new device",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;

        let block = chain.mineBlock([
            Tx.contractCall('lumi-control', 'register-device', [
                types.uint(1)
            ], deployer.address),
            // Non-owner registration should fail
            Tx.contractCall('lumi-control', 'register-device', [
                types.uint(2)
            ], wallet1.address)
        ]);

        block.receipts[0].result.expectOk();
        block.receipts[1].result.expectErr(types.uint(100)); // ERR_NOT_AUTHORIZED
    }
});

Clarinet.test({
    name: "Can control device state",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        
        // Register device
        let block = chain.mineBlock([
            Tx.contractCall('lumi-control', 'register-device', [
                types.uint(1)
            ], deployer.address)
        ]);
        
        // Toggle light
        block = chain.mineBlock([
            Tx.contractCall('lumi-control', 'toggle-light', [
                types.uint(1)
            ], deployer.address)
        ]);
        
        block.receipts[0].result.expectOk();
        
        // Check status
        let statusBlock = chain.mineBlock([
            Tx.contractCall('lumi-control', 'get-device-status', [
                types.uint(1)
            ], deployer.address)
        ]);
        
        const status = statusBlock.receipts[0].result.expectOk().expectTuple();
        assertEquals(status['is-on'], true);
    }
});

Clarinet.test({
    name: "Can create and manage device groups",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        
        // Create group
        let block = chain.mineBlock([
            Tx.contractCall('lumi-control', 'create-group', [
                types.uint(1),
                types.ascii("Living Room")
            ], deployer.address)
        ]);
        
        block.receipts[0].result.expectOk();
        
        // Register device and add to group
        block = chain.mineBlock([
            Tx.contractCall('lumi-control', 'register-device', [
                types.uint(1)
            ], deployer.address),
            Tx.contractCall('lumi-control', 'add-to-group', [
                types.uint(1),
                types.uint(1)
            ], deployer.address)
        ]);
        
        block.receipts[0].result.expectOk();
        block.receipts[1].result.expectOk();
    }
});

Clarinet.test({
    name: "Can create schedules",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('lumi-control', 'create-schedule', [
                types.uint(1), // schedule id
                types.uint(1), // target id
                types.ascii("device"), // target type
                types.ascii("toggle"), // action
                types.uint(1), // value
                types.uint(100) // trigger block
            ], deployer.address)
        ]);
        
        block.receipts[0].result.expectOk();
    }
});
