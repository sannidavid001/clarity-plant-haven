import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensure user can register and username is unique",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get('wallet_1')!;
    const wallet2 = accounts.get('wallet_2')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('plant-haven', 'register-user', [
        types.ascii("plant_lover_1")
      ], wallet1.address)
    ]);
    
    block.receipts[0].result.expectOk();
    
    // Try to register same username with different wallet
    let block2 = chain.mineBlock([
      Tx.contractCall('plant-haven', 'register-user', [
        types.ascii("plant_lover_1")
      ], wallet2.address)
    ]);
    
    block2.receipts[0].result.expectErr(types.uint(103)); // err-already-exists
  }
});

[Previous tests remain unchanged...]

Clarinet.test({
  name: "Ensure plant information can be updated by owner",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get('wallet_1')!;
    
    // First add a plant
    let block = chain.mineBlock([
      Tx.contractCall('plant-haven', 'add-plant', [
        types.ascii("Monstera Deliciosa"),
        types.ascii("Beautiful swiss cheese plant"),
        types.ascii("Water weekly, indirect light")
      ], wallet1.address)
    ]);
    
    // Update plant information
    let updateBlock = chain.mineBlock([
      Tx.contractCall('plant-haven', 'update-plant', [
        types.uint(0),
        types.ascii("Monstera Deliciosa"),
        types.ascii("Updated description"),
        types.ascii("Updated care instructions")
      ], wallet1.address)
    ]);
    
    updateBlock.receipts[0].result.expectOk();
    
    // Verify updated information
    let plantInfo = chain.mineBlock([
      Tx.contractCall('plant-haven', 'get-plant-info', [
        types.uint(0)
      ], wallet1.address)
    ]);
    
    const plantData = plantInfo.receipts[0].result.expectSome();
    assertEquals(plantData['description'], "Updated description");
    assertEquals(plantData['care-instructions'], "Updated care instructions");
  }
});
