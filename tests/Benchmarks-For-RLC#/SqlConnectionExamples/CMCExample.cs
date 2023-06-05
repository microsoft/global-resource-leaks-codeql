using System;
using System.Data.SqlClient;

namespace SqlConnectionExamples
{
    public class CMCExample
    {
        SqlConnection connection;

        private static SqlConnection GetSqlConnection()
        {
            SqlConnectionStringBuilder builder = new SqlConnectionStringBuilder();
            builder.ConnectionString = "Server=tcp:cloud-reliability.database.windows.net,1433;Initial Catalog=leaks;Persist Security Info=False;User ID=resourceleaks;Password=ResourceLe@ks;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=300;";
            var sqlconnection = new SqlConnection(builder.ConnectionString);

            return sqlconnection;
        }

        public CMCExample() 
        { 
            connection = GetSqlConnection();
        }

        public SqlConnection GetConnection()
        {
            return connection;
        }

        public void correctReset()
        {
            connection.Close();

            connection = GetSqlConnection();
        }

        public void incorrectReset()
        {
            connection = GetSqlConnection();
        }

        public void Dispose()
        {
            this.connection.Dispose();
        }

        public void runSqlQuery()
        {
            String sql = "select top 10 FirstName, LastName from [SalesLT].[Customer]";

            using (SqlCommand command = new SqlCommand(sql, GetConnection()))
            {
                using (SqlDataReader reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        Console.WriteLine("{0} {1}", reader.GetString(0), reader.GetString(1));
                    }
                }
            }
        }

        public static void main()
        {
            Console.WriteLine($"Total memory: {GC.GetTotalMemory(true) / 1024f / 1024f} MB" + "\n---------------------------------------\n");

            CMCExample c1 = new CMCExample(); // No resource leak

            c1.runSqlQuery();
            c1.correctReset(); // previous resource released and new resource allocated - no resource leak
            c1.Dispose(); 

            CMCExample c2 = new CMCExample(); // Resource leak

            c2.runSqlQuery();
            c2.incorrectReset(); // New resource allocated - no resource leak
            c2.Dispose();

            CMCExample c3 = new CMCExample(); // No resource leak

            c3.runSqlQuery();
            c3.correctReset(); // New resource allocated - resource leak

            CMCExample c4 = new CMCExample(); // Resource leak

            c4.runSqlQuery();
            c4.incorrectReset(); // New resource allocated - resource leak

            GC.Collect();
            GC.WaitForFullGCComplete();
            Console.WriteLine("---------------------------------------\n" + $"Total memory: {GC.GetTotalMemory(true) / 1024f / 1024f} MB");
        }
    }
}
