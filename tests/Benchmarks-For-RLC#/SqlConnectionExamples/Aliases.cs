using System;
using System.Data.SqlClient;

namespace SqlConnectionExamples
{
    public class SqlConnectionWrapper
    {
        SqlConnection connection;

        public SqlConnectionWrapper(SqlConnection con)
        {
            this.connection = con;
        }

        public SqlConnection GetConnection()
        {
            return connection;
        }

        public void Dispose() 
        { 
            this.connection.Dispose(); 
        }
    }

    public class Aliases
    {
        public static SqlConnection GetSqlConnection()
        {
            SqlConnectionStringBuilder builder = new SqlConnectionStringBuilder();
            builder.ConnectionString = "Server=tcp:database.windows.net,1433;Initial Catalog=leaks;Persist Security Info=False;User ID=resourceleaks;Password=ResourceLe@ks;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=300;";
            var sqlconnection = new SqlConnection(builder.ConnectionString);

            return sqlconnection;
        }

        public static void runSqlQuery(System.Data.SqlClient.SqlConnection con)
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

        public static void findAliases()
        {
            SqlConnection con = GetSqlConnection(); // No resource leak

            SqlConnectionWrapper cw = new SqlConnectionWrapper(con); // Resource aliases

            runSqlQuery(cw.GetConnection());  

            cw.Dispose(); 
        }

        public static void usingStmt()
        {
            using SqlConnection con = GetSqlConnection(); // No resource leak because of using statement

            SqlConnectionWrapper cw = new SqlConnectionWrapper(con); // Resource aliases

            runSqlQuery(cw.GetConnection());
        }

        public static void exceptionalPaths1()
        {
            try
            {
                SqlConnection con = GetSqlConnection(); // Resource leak along exceptional path

                SqlConnectionWrapper cw = new SqlConnectionWrapper(con); // Resource aliases

                runSqlQuery(cw.GetConnection());

                cw.Dispose();
            }
            catch (Exception ex) { }
            
        }

        public static void exceptionalPaths2()
        {
            SqlConnection con = null;

            try
            {
                con = GetSqlConnection(); // No resource leak

                SqlConnectionWrapper cw = new SqlConnectionWrapper(con); // Resource aliases

                runSqlQuery(cw.GetConnection());

                cw.Dispose();
            }
            catch (Exception ex) { }
            finally
            {
                if (con != null)
                    con.Dispose();
            }

        }

        public static void multipleSinks()
        {
            Console.WriteLine("Enter count: ");
            int count = Convert.ToInt32(Console.ReadLine());

            SqlConnection con = GetSqlConnection(); // No resource leak

            SqlConnectionWrapper cw = new SqlConnectionWrapper(con); // Resource aliases

            runSqlQuery(cw.GetConnection());

            if(count > 10)
                cw.Dispose(); // Dispose 1
            else
                con.Dispose(); // Dispose 2
        }

        public static void main()
        {
            Console.WriteLine($"Total memory: {GC.GetTotalMemory(true) / 1024f / 1024f} MB" + "\n---------------------------------------\n");

            findAliases();
            exceptionalPaths1();
            exceptionalPaths2();
            multipleSinks();
            usingStmt();

            GC.Collect();
            GC.WaitForFullGCComplete();
            Console.WriteLine("---------------------------------------\n" + $"Total memory: {GC.GetTotalMemory(true) / 1024f / 1024f} MB");
        }

    }
}
