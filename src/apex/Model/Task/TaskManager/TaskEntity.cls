public interface TaskEntity {

	void refresh();
	String getTarget();
	String getType();
	String getErrorMessage();
	Boolean completeTask();

}