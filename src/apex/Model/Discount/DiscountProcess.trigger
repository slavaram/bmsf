trigger DiscountProcess on Discount__c (before insert, after insert, before update, after update, before delete) {

/*
	2013/03/29	|	Kudryavtsev Roman
*/
	Map<Id,Discount__c> discountsBeforeChangesMap = Trigger.oldMap;
	Map<Id,Discount__c> discountsAfterChangesMap = Trigger.newMap;
	
	List<Discount__c> discountsBeforeChangesList = Trigger.old;
	List<Discount__c> discountsAfterChangesList = Trigger.new;
	
	List<Discount__c> discountsToFetch = new List<Discount__c>();
	if(Trigger.isDelete){
		discountsToFetch = discountsBeforeChangesList;
	}else if(Trigger.isUpdate || Trigger.isInsert){
		discountsToFetch = discountsAfterChangesList;
	}
	 
	 
	 DiscountExcecutor discountExcecutor = new DiscountExcecutor();
	 discountExcecutor.prepareData(discountsToFetch);
	//Map<Id,List<Discount__c>> totalChildsMap = new Map<Id,Discount__c>();
	
	// fetch All parents
	
	// fetch All childs
	
	// getMap from current discounts to parents
	
	// getMap from child (not current) discounts to parents
	if(Trigger.isBefore && Trigger.isInsert){
		
		discountExcecutor.excecuteInsert(discountsAfterChangesList);
		/*
			set agregate values from patents
		*/
		/* GARBAGE
		if(discountsAfterChangesList!=null){
			
			
			for(Discount__c insertDiscount:discountsAfterChangesList){
				//actions:
				//find the parents 
				List<Discount__c> fetchedParentDiscountList = DiscountExcecutor.fetcheParentDiscountList(insertDiscount);
				if(fetchedParentDiscountList == null || fetchedParentDiscountList.size()<1) continue;
				//calculate values
				//calculate absolute 
				Double aggregateAbsoluteDiscount = DiscountExcecutor.calculateNewAbsoluteDiscountValue(insertDiscount, fetchedParentDiscountList);
				insertDiscount.AbsolutelyDiscount__c = aggregateAbsoluteDiscount;
				
				//calculate percent
				Double aggreagatePercentDiscount = DiscountExcecutor.calculateNewPercentDiscountValue(insertDiscount, fetchedParentDiscountList);
				insertDiscount.Discount__c = aggreagatePercentDiscount;
				//set agregate values including local values
			}
				
		}
		*/	
			
	}else if(Trigger.isAfter && Trigger.isInsert){
		
		// DO NOTHING!!!
		/*
		
		 add for new childs of current action
		*/
		
		
		/* GARBAGE
		if(discountsAfterChangesList!=null){
			
			List<Discount__c> fetchAllChilds = new  List<Discount__c>();
			Boolean isAddOperation =true;
			
			for(Discount__c insertDiscount:discountsAfterChangesList){
				//actions:
				//find all the childs
				List<Discount__c> fetchedChildDiscountList;
		
				//calculate discount values for each child
				for(Discount__c childDiscount:fetchedChildDiscountList){
						childDiscount.IsParentDiscountInclude__c = false;
						
						Double aggregateAbsoluteDiscount = DiscountExcecutor.calculateNewAbsoluteDiscountValue(insertDiscount, childDiscount, isAddOperation);
						childDiscount.AbsolutelyDiscount__c = aggregateAbsoluteDiscount;
						
						Double aggreagatePercentDiscount = DiscountExcecutor.calculateNewPercentDiscountValue(insertDiscount, childDiscount, isAddOperation);
						childDiscount.Discount__c = aggreagatePercentDiscount;
				}
				
				fetchAllChilds.addAll(fetchedChildDiscountList);
			}
			
			//update all childs 4 all new discounts
			update fetchAllChilds;
				
		}
		
		*/
	}
	else if(Trigger.isBefore && Trigger.isUpdate){
		
			//Boolean isNotAddOperation =false;
			//Boolean isAddOperation =true;
			
			
			discountExcecutor.excecuteUpdate(discountsBeforeChangesMap, discountsAfterChangesMap);
			
			/* GARBAGE
			// exclusive all same dicsounts for which update time is 
			Map<Id,Discount__c> unicDiscountMap = getUnicMapWithLastModifiedTime(discountsAfterChangesList);
			
			if( discountsBeforeChangesList!=null){
				for(Discount__c beforeDiscount:discountsBeforeChangesList){
					if(beforeDiscount.IsParentDiscountInclude__c){
					
						//calculate values
						//set agregate values including local values
						
						List<Discount__c> fetchAllChilds = new  List<Discount__c>();
						//actions:
						//find all the childs
						List<Discount__c> fetchedChildDiscountListToAdd;
		
						//incalculate discount values for each child
						for(Discount__c childDiscount:fetchedChildDiscountListToAdd){
							childDiscount.IsParentDiscountInclude__c = false;
						
							Double aggregateAbsoluteDiscount = DiscountExcecutor.calculateNewAbsoluteDiscountValue(beforeDiscount, childDiscount, isAddOperation);
							childDiscount.AbsolutelyDiscount__c = aggregateAbsoluteDiscount;
						
							Double aggreagatePercentDiscount = DiscountExcecutor.calculateNewPercentDiscountValue(beforeDiscount, childDiscount, isAddOperation);
							childDiscount.Discount__c = aggreagatePercentDiscount;
						}
				
						fetchAllChilds.addAll(fetchedChildDiscountListToAdd);
				
						//decalculate discount values for each child
						List<Discount__c> fetchedChildDiscountListToSubstract;
						for(Discount__c childDiscount:fetchedChildDiscountListToSubstract){
							childDiscount.IsParentDiscountInclude__c = false;
						
							Double aggregateAbsoluteDiscount = DiscountExcecutor.calculateNewAbsoluteDiscountValue(beforeDiscount, childDiscount, isNotAddOperation);
							childDiscount.AbsolutelyDiscount__c = aggregateAbsoluteDiscount;
						
							Double aggreagatePercentDiscount = DiscountExcecutor.calculateNewPercentDiscountValue(beforeDiscount, childDiscount, isNotAddOperation);
							childDiscount.Discount__c = aggreagatePercentDiscount;
						}
				
						fetchAllChilds.addAll(fetchedChildDiscountListToSubstract);
						
			
						//update all childs 4 all new discounts
						update fetchAllChilds;
						
					}else{
						beforeDiscount.IsParentDiscountInclude__c = true;
						
					}
				
				}
			}	
			*/
	}else if(Trigger.isBefore && Trigger.isDelete){
		
		discountExcecutor.excecuteDelete(discountsBeforeChangesList);
		/*
			remove for exsits childs
			the code is the same as to the cases if(Trigger.isAfter && Trigger.isInsert) and if(Trigger.isAfter && Trigger.isUpdate)
		*/
		
		/*
		if(discountsBeforeChangesList!=null){
			Boolean isNotAddOperation =false;
			
			List<Discount__c> fetchAllChilds = new  List<Discount__c>();
			
			for(Discount__c beforeDiscount:discountsBeforeChangesList){
				
				//decalculate discount values for each child
				List<Discount__c> fetchedChildDiscountListToSubstract;
				for(Discount__c childDiscount:fetchedChildDiscountListToSubstract){
						childDiscount.IsParentDiscountInclude__c = false;
						
						Double aggregateAbsoluteDiscount = DiscountExcecutor.calculateNewAbsoluteDiscountValue(beforeDiscount, childDiscount, isNotAddOperation);
						childDiscount.AbsolutelyDiscount__c = aggregateAbsoluteDiscount;
						
						Double aggreagatePercentDiscount = DiscountExcecutor.calculateNewPercentDiscountValue(beforeDiscount, childDiscount, isNotAddOperation);
						childDiscount.Discount__c = aggreagatePercentDiscount;
						
				}
				
				fetchAllChilds.addAll(fetchedChildDiscountListToSubstract);
			}
			
			//update all childs 4 all new discounts
			update fetchAllChilds;
		}
		*/
		
	}
}