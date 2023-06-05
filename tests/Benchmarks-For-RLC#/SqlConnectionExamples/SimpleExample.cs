using System;
using System.Data.SqlClient;

namespace SqlConnectionExamples
{
    public class SimpleExample
    {
        private static SqlConnection GetSqlConnection()
        {
            SqlConnectionStringBuilder builder = new SqlConnectionStringBuilder();
            builder.ConnectionString = "Server=tcp:cloud-reliability.database.windows.net,1433;Initial Catalog=leaks;Persist Security Info=False;User ID=resourceleaks;Password=ResourceLe@ks;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=300;";
            var sqlconnection = new SqlConnection(builder.ConnectionString);

            return sqlconnection;
        }

        public static void runSqlQuery(SqlConnection con)
        {
            String sql = "select top 10 FirstName, LastName from [SalesLT].[Customer]";

            using (SqlCommand command = new SqlCommand(sql, con))
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

        public static void closeConnection(SqlConnection con)
        {
            con.Close();
        }

        public static void main()
        {
            Console.WriteLine($"Total memory: {GC.GetTotalMemory(true) / 1024f / 1024f} MB" + "\n---------------------------------------\n");

            SqlConnection con1 = GetSqlConnection(); // No resource leak

            runSqlQuery(con1);

            closeConnection(con1);

            SqlConnection con2 = GetSqlConnection(); // Resource leak

            runSqlQuery(con2);

            GC.Collect();
            GC.WaitForFullGCComplete();
            Console.WriteLine("---------------------------------------\n" + $"Total memory: {GC.GetTotalMemory(true) / 1024f / 1024f} MB");
        }
    }
}
