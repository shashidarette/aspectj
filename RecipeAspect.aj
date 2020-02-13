package coffeemaker;

import java.util.ArrayList;
import java.util.List;

import org.aspectj.lang.reflect.CodeSignature;

/**
 * 
 * @author Shashidar Ette : se146
 * This is the aspect created for GD Assignment 2 for AspectJ/SPL
 * 
 */
public aspect RecipeAspect {
	// Holds the maximum number of units of an ingredient in a Recipe.
	private static final int MAX_INGREDIENT_UNITS = 30;

	/*
	 * Utility function to print the string message on console.
	 */
	static final void println(String s) {
		System.out.println(s);
	}

	/*
	 * Q1: 
	 * Understanding:
	 * The concern is any recipe should allow only up to max of 30 units of any ingredient.
	 * In case of CoffeeMaker, the ingredients are added to a recipe via setAmt* methods of Recipe class 
	 * i.e. setAmtChocolate, setAmtCoffee, setAmtMilk, setAmtSugar
	 * Each of the methods take an int as amount of units for an ingredient.
	 * 
	 * Solution:
	 * - To provide a "pointcut" which considers all calls to Recipe.setAmt* methods
	 * - On top of the pointcut, we want to validate the amount of units for an ingredient before 
	 *   it is added to Recipe, a "before" advice is used.
	 * - Validation of Ingredient is done in a utility function validateIngriendiantCount(int)
	 * 
	 */
	pointcut setIngredientUnitsCall() :
		call (void Recipe.setAmt*(int));
	
	/**
	 * advice for set ingredient validation concern
	 */
	before() : setIngredientUnitsCall() {
		Object[] args = thisJoinPoint.getArgs();
		int value = 0;
		
		// NULL check to avoid null pointer exception
		if (args[0] != null) {
			value = (int) args[0];
		}
		validateIngriendiantCount(value);
	}
	
	/*
	 * Utility function to validate the number of units an Ingredient in a recipe
	 */
	void validateIngriendiantCount(int count) throws IllegalArgumentException {
		if (count > MAX_INGREDIENT_UNITS) {
			throw new IllegalArgumentException("Recipe can allow only up to" 
					+ MAX_INGREDIENT_UNITS + " units of an ingridient.");
		}
	}

	/*
	 * Q2. 
	 * Part 1 - 
	 * Understanding:
	 * The concern is to implement tracing functionality to print the information of Inventory object
	 * only when addInventory object is called.
	 * 
	 * Solution:
	 * - A "pointcut" is considered for calls to CoffeeMaker.addInventory()
	 * - To print the state of Inventory object prior and later to the execution of addInventory,
	 * "before" and "after" advises are used.
	 * 
	 */
	//=========================== Q2. PART-1 ======================================//
	pointcut addInventoryCall(CoffeeMaker c) : target(c) &&
		call (boolean addInventory(int, int, int, int));
	
	before(CoffeeMaker c) : addInventoryCall(c) {
		println("Before: CoffeeMaker.addInventory");
		// get information from Inventory before addInventory
		println(c.checkInventory().toString());
	}
	
	after(CoffeeMaker c) : addInventoryCall(c) {
		println("After: CoffeeMaker.addInventory");
		// get information from Inventory after addInventory
		println(c.checkInventory().toString());
	}
	
	//=========================== Q2. PART-2 ======================================//
	/*
	 * Part - 2:
	 * Understanding:
	 * In addition to tracing, the concern is that when an Inventory object is updated for an ingredient.
	 * It should check that resulting value should not exceed MAX_INGREDIENT_UNITS. 
	 * If it is higher the value should be set to MAX_INGREDIENT_UNITS.
	 * 
	 * Solution:
	 * - A "pointcut" is consider for calls to Inventory.set*() methods
	 * - An "around" advice is used to validate amount of ingredient units and 
	 * set to MAX_INGREDIENT_UNITS if its high.
	 * 
	 */
	pointcut updateInventoryCall(int amount) : 
		call (void Inventory.set*(int)) && args(amount);
	
	void around(int amount) : 
		updateInventoryCall(amount) {		
		if (amount > MAX_INGREDIENT_UNITS) {
			String[] names = ((CodeSignature) thisJoinPoint.getSignature()).getParameterNames();			
			println("Inventory cannot have more than " 
					+ MAX_INGREDIENT_UNITS + " units of "+ names[0] 
					+ ". Setting it to " +  MAX_INGREDIENT_UNITS + ".");
			amount = MAX_INGREDIENT_UNITS;
		}
		proceed(amount);
	}
	
	/*
	 * Q3.
	 * Understanding:
	 * The concern is that value provided from console (mainly integer inputs) should be
	 * validated whether its a positive number.
	 * In case of CoffeeMaker solution, MainClass uses "stringToInt" function to convert the string
	 * provided by the user in console. Hence the value passed to it should be considered.
	 * 
	 * Solution:
	 * - A "pointcut" is considered for Main.stringToInt(String)
	 * - An "around" advice is used to check the value returned from stringToInt.
	 * If the value returned is negative, relevant message is shown to user on console.
	 * 
	 */
	pointcut inputConsole() : 
		call (int Main.stringToInt(String));
	
	
	int around() : inputConsole() {
		int value = proceed();		
		if (value < 0) {
			println("The value should be a positive number.");
		}
		return value;
	}
	
	/*
	 * Q4.
	 * a. This aspect is to check whether there are enoughIngridients before preparing any recipe.
	 * This helps to warn the user, that there are not enough ingredients to make the selected recipe.
	 * 
	 * Solution:
	 * - A "pointcut" to consider call to Inventory.enoughIngredients(Recipe)
	 * - An "around" advice is used to check the boolean return value from  enoughIngredients,
	 * warn the user appropriately.
	 */
	pointcut checkEnoughIngridients() : 
		call (boolean Inventory.enoughIngredients(Recipe));
	
	boolean around() : checkEnoughIngridients() {
		boolean value = proceed();
		if (!value) {
			println("There are not enough ingredients to make the recipe.");
		}
		return value;
	}
	
	/*
	 * Q4.
	 * b. This aspect is to check whether there are valid recipe before a Coffee can be prepared
	 * In addition to the aspect, the code in Main.deleteRecipe, Main.editRecipe, Main.makeCoffee 
	 * have been modified to check whether the recipe options are available for preparation or not.
	 * Solution:
	 * - A "pointcut" to consider call to CoffeeMaker.getRecipes()
	 * - An "around" advice is to used check the null recipes, if there are no valid recipes
	 *   warn the user appropriately.
	 */
	pointcut checkValidRecipes() : 
		call (Recipe[] CoffeeMaker.getRecipes());
	
	Recipe[] around() : checkValidRecipes() {
		Recipe[] recipes = proceed();
		List<Recipe> list = new ArrayList<Recipe>();
		for(int i = 0; i < recipes.length; i++) {
            if (recipes[i].getName() != null) {
            	list.add(recipes[i]);
            }
        }
		
		if (list.size() == 0) {
			println("There are no valid recipes are available in the system.");
		}
		return list.toArray(new Recipe[list.size()]);
	}
}
