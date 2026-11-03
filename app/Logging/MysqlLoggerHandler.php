<?php
namespace App\Logging;

use Illuminate\Support\Facades\Log;
use Monolog\Handler\AbstractProcessingHandler;
use Monolog\Level;
use Monolog\LogRecord;
use App\Models\Log as LogModel;

class MysqlLoggerHandler extends AbstractProcessingHandler
{
    public function __construct(int|string|Level $level = Level::Debug, bool $bubble = true)
    {
        parent::__construct($level, $bubble);
    }

    protected function write(LogRecord $record): void
    {
        try{
            $context = $record->context;
            $extra = $record->extra;
            if(isset($context['exception']) && is_object($context['exception'])){
                $context['exception'] = (array)$context['exception'];
            }
            $requestData = request()->all() ?? [];
            $timestamp = $record->datetime->getTimestamp();
            $log = [
                'title' => $record->message,
                'level' => $record->level->getName(),
                'host' => $extra['request_host'] ?? request()->getSchemeAndHttpHost(),
                'uri' => $extra['request_uri'] ?? request()->getRequestUri(),
                'method' => $extra['request_method'] ?? request()->getMethod(),
                'ip' => request()->getClientIp(),
                'data' => json_encode($requestData),
                'context' => json_encode($context),
                'created_at' => $timestamp,
                'updated_at' => $timestamp,
            ];

            LogModel::insert(
                $log
            );
        }catch (\Throwable $e){
            // 只有在 APP_DEBUG 为 true 时才写入日志文件
            if (config('app.debug')) {
                Log::channel('daily')->error($e->getMessage().$e->getFile().$e->getTraceAsString());
            }
        }
    }
}
